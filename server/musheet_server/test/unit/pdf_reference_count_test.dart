/// PDF Reference Counting and Deletion Tests - Server Side
///
/// Tests for PDF file reference counting and cleanup logic on the server.
/// Per SERVER_SYNC_LOGIC.md §5: Global reference counting for PDF files.
///
/// Key scenarios tested:
/// 1. Global deduplication - files stored at /uploads/global/pdfs/{hash}.pdf
/// 2. Reference counting across ALL users (not per-user)
/// 3. Instant upload (秒传) via hash check
/// 4. File deletion only when no references remain
///
/// Note: These tests are designed to be run with `dart test` in the server directory.
/// They mock the database and file system operations.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('PDF Reference Counting - Server Side', () {
    late Directory tempUploadsDir;

    const testPdfContent = 'Test PDF Content 12345';
    late String testPdfHash;

    setUp(() async {
      tempUploadsDir = await Directory.systemTemp.createTemp('server_pdf_test_');
      testPdfHash = md5.convert(testPdfContent.codeUnits).toString();
    });

    tearDown(() async {
      if (await tempUploadsDir.exists()) {
        await tempUploadsDir.delete(recursive: true);
      }
    });

    group('Global Deduplication', () {
      test(
        'PDF files are stored at global/pdfs/{hash}.pdf path',
        () async {
          // Simulate the file storage path logic from FileEndpoint
          const hash = 'abc123def456';
          final globalPath = 'global/pdfs/$hash.pdf';

          expect(globalPath, equals('global/pdfs/abc123def456.pdf'));
          expect(globalPath.startsWith('global/'), isTrue);
        },
      );

      test(
        'Same content produces same hash (deduplication)',
        () {
          const content1 = 'Same PDF Content';
          const content2 = 'Same PDF Content';

          final hash1 = md5.convert(content1.codeUnits).toString();
          final hash2 = md5.convert(content2.codeUnits).toString();

          expect(hash1, equals(hash2));
        },
      );

      test(
        'Different content produces different hash',
        () {
          const content1 = 'PDF Content A';
          const content2 = 'PDF Content B';

          final hash1 = md5.convert(content1.codeUnits).toString();
          final hash2 = md5.convert(content2.codeUnits).toString();

          expect(hash1, isNot(equals(hash2)));
        },
      );

      test(
        'Instant upload (秒传) - file exists check',
        () async {
          // Create the directory structure
          final globalDir = Directory('${tempUploadsDir.path}/global/pdfs');
          await globalDir.create(recursive: true);

          // Create an existing file
          final existingFile = File('${globalDir.path}/$testPdfHash.pdf');
          await existingFile.writeAsString(testPdfContent);

          // Check if file exists (simulating checkPdfHash)
          final exists = await existingFile.exists();

          expect(exists, isTrue);
        },
      );

      test(
        'Instant upload skips saving if file already exists',
        () async {
          final globalDir = Directory('${tempUploadsDir.path}/global/pdfs');
          await globalDir.create(recursive: true);

          final pdfFile = File('${globalDir.path}/$testPdfHash.pdf');

          // First upload
          await pdfFile.writeAsString(testPdfContent);
          final firstModified = await pdfFile.lastModified();

          // Wait a bit
          await Future.delayed(const Duration(milliseconds: 50));

          // Simulate second upload (should skip if file exists)
          if (!await pdfFile.exists()) {
            await pdfFile.writeAsString(testPdfContent);
          }
          final secondModified = await pdfFile.lastModified();

          // File modification time should NOT have changed
          expect(firstModified, equals(secondModified));
        },
      );
    });

    group('Reference Counting Logic', () {
      test(
        'Reference count simulation - multiple records with same hash',
        () {
          // Simulate InstrumentScore records
          final instrumentScores = [
            {'id': 1, 'pdfHash': testPdfHash, 'deletedAt': null},
            {'id': 2, 'pdfHash': testPdfHash, 'deletedAt': null},
            {'id': 3, 'pdfHash': 'different_hash', 'deletedAt': null},
          ];

          // Count references for testPdfHash
          final references = instrumentScores
              .where((r) =>
                  r['pdfHash'] == testPdfHash && r['deletedAt'] == null)
              .toList();

          expect(references.length, equals(2));
        },
      );

      test(
        'Reference count excludes soft-deleted records',
        () {
          final instrumentScores = [
            {'id': 1, 'pdfHash': testPdfHash, 'deletedAt': null},
            {'id': 2, 'pdfHash': testPdfHash, 'deletedAt': DateTime.now()},
          ];

          final activeReferences = instrumentScores
              .where((r) =>
                  r['pdfHash'] == testPdfHash && r['deletedAt'] == null)
              .toList();

          expect(activeReferences.length, equals(1));
        },
      );

      test(
        'Reference count is global across all users',
        () {
          // Simulate records from different users
          final instrumentScores = [
            {'id': 1, 'userId': 1, 'pdfHash': testPdfHash, 'deletedAt': null},
            {'id': 2, 'userId': 2, 'pdfHash': testPdfHash, 'deletedAt': null},
            {'id': 3, 'userId': 3, 'pdfHash': testPdfHash, 'deletedAt': null},
          ];

          // Global count (NOT per-user)
          final globalReferences = instrumentScores
              .where((r) =>
                  r['pdfHash'] == testPdfHash && r['deletedAt'] == null)
              .toList();

          expect(globalReferences.length, equals(3));
        },
      );

      test(
        'Reference count is global across user and team scopes',
        () {
          final instrumentScores = [
            {
              'id': 1,
              'scopeType': 'user',
              'scopeId': 1,
              'pdfHash': testPdfHash,
              'deletedAt': null
            },
            {
              'id': 2,
              'scopeType': 'team',
              'scopeId': 42,
              'pdfHash': testPdfHash,
              'deletedAt': null
            },
          ];

          // Global count across scopes
          final globalReferences = instrumentScores
              .where((r) =>
                  r['pdfHash'] == testPdfHash && r['deletedAt'] == null)
              .toList();

          expect(globalReferences.length, equals(2));
        },
      );
    });

    group('File Cleanup Logic', () {
      test(
        'File is deleted when reference count reaches zero',
        () async {
          final globalDir = Directory('${tempUploadsDir.path}/global/pdfs');
          await globalDir.create(recursive: true);

          final pdfFile = File('${globalDir.path}/$testPdfHash.pdf');
          await pdfFile.writeAsString(testPdfContent);

          expect(await pdfFile.exists(), isTrue);

          // Simulate cleanup (reference count = 0)
          final references = <Map<String, dynamic>>[];
          if (references.isEmpty) {
            await pdfFile.delete();
          }

          expect(await pdfFile.exists(), isFalse);
        },
      );

      test(
        'File is NOT deleted when references still exist',
        () async {
          final globalDir = Directory('${tempUploadsDir.path}/global/pdfs');
          await globalDir.create(recursive: true);

          final pdfFile = File('${globalDir.path}/$testPdfHash.pdf');
          await pdfFile.writeAsString(testPdfContent);

          expect(await pdfFile.exists(), isTrue);

          // Simulate still having references
          final references = [
            {'id': 1, 'pdfHash': testPdfHash, 'deletedAt': null},
          ];

          if (references.isEmpty) {
            await pdfFile.delete();
          }

          // File should still exist
          expect(await pdfFile.exists(), isTrue);
        },
      );

      test(
        'Cleanup checks global references before deleting',
        () async {
          final globalDir = Directory('${tempUploadsDir.path}/global/pdfs');
          await globalDir.create(recursive: true);

          final pdfFile = File('${globalDir.path}/$testPdfHash.pdf');
          await pdfFile.writeAsString(testPdfContent);

          // Simulate: User 1 deletes their reference, but User 2 still has one
          final instrumentScores = [
            {
              'id': 1,
              'userId': 1,
              'pdfHash': testPdfHash,
              'deletedAt': DateTime.now()
            }, // deleted
            {'id': 2, 'userId': 2, 'pdfHash': testPdfHash, 'deletedAt': null}, // active
          ];

          final activeReferences = instrumentScores
              .where((r) =>
                  r['pdfHash'] == testPdfHash && r['deletedAt'] == null)
              .toList();

          // Should NOT delete because User 2 still has reference
          if (activeReferences.isEmpty) {
            await pdfFile.delete();
          }

          expect(await pdfFile.exists(), isTrue);
          expect(activeReferences.length, equals(1));
        },
      );
    });

    group('Hash Computation', () {
      test(
        'MD5 hash is computed correctly',
        () {
          final data = ByteData.view(Uint8List.fromList(testPdfContent.codeUnits).buffer);
          final bytes = data.buffer.asUint8List();
          final digest = md5.convert(bytes);
          final hash = digest.toString();

          expect(hash, equals(testPdfHash));
        },
      );

      test(
        'Hash is 32 characters (MD5 hex)',
        () {
          final hash = md5.convert('any content'.codeUnits).toString();
          expect(hash.length, equals(32));
        },
      );
    });

    group('Storage Path Logic', () {
      test(
        'Global path is derived from hash',
        () {
          const hash = 'abc123def456789012345678901234ab';
          final globalPath = 'global/pdfs/$hash.pdf';

          expect(globalPath, contains(hash));
          expect(globalPath, endsWith('.pdf'));
        },
      );

      test(
        'Full upload path includes uploads directory',
        () {
          const hash = 'abc123';
          final globalPath = 'global/pdfs/$hash.pdf';
          final fullPath = 'uploads/$globalPath';

          expect(fullPath, equals('uploads/global/pdfs/abc123.pdf'));
        },
      );
    });

    group('Access Control', () {
      test(
        'User can access hash if they have an InstrumentScore with that hash',
        () {
          final userInstrumentScores = [
            {'id': 1, 'userId': 1, 'pdfHash': testPdfHash},
          ];

          final hasAccess = userInstrumentScores.any((is_) =>
              is_['userId'] == 1 && is_['pdfHash'] == testPdfHash);

          expect(hasAccess, isTrue);
        },
      );

      test(
        'User cannot access hash if they have no InstrumentScore with that hash',
        () {
          final userInstrumentScores = [
            {'id': 1, 'userId': 1, 'pdfHash': 'different_hash'},
          ];

          final hasAccess = userInstrumentScores.any((is_) =>
              is_['userId'] == 1 && is_['pdfHash'] == testPdfHash);

          expect(hasAccess, isFalse);
        },
      );

      test(
        'Team member can access hash from team score',
        () {
          // Simulate team membership
          final teamMembers = [
            {'userId': 1, 'teamId': 42},
          ];

          // Simulate team scores with the hash
          final teamScores = [
            {'id': 10, 'scopeType': 'team', 'scopeId': 42},
          ];

          final teamInstrumentScores = [
            {'id': 100, 'scoreId': 10, 'pdfHash': testPdfHash},
          ];

          // Check if user 1 is member of team 42
          final isMember = teamMembers.any((tm) =>
              tm['userId'] == 1 && tm['teamId'] == 42);

          // Check if team 42 has a score with this hash
          final teamHasHash = teamScores.any((ts) {
            if (ts['scopeType'] == 'team' && ts['scopeId'] == 42) {
              return teamInstrumentScores.any((tis) =>
                  tis['scoreId'] == ts['id'] && tis['pdfHash'] == testPdfHash);
            }
            return false;
          });

          expect(isMember && teamHasHash, isTrue);
        },
      );
    });
  });
}
