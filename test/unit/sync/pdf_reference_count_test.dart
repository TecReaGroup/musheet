/// PDF Reference Counting and Deletion Tests
///
/// Tests for PDF file reference counting and cleanup logic.
/// Per APP_SYNC_LOGIC.md §3.5: Global reference counting for PDF files.
///
/// Key scenarios:
/// 1. Multiple InstrumentScores can reference the same pdfHash
/// 2. PDF files are only deleted when ALL references are removed
/// 3. Hash-based deduplication across user library and teams
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/database/database.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Reference Counting - Client Side', () {
    late AppDatabase testDb;
    late Directory tempDir;

    const testPdfHash = 'abc123def456';
    const testPdfHash2 = 'xyz789abc012';

    setUp(() async {
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('pdf_test_');
    });

    tearDown(() async {
      await testDb.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Reference Count Tracking', () {
      test(
        'Multiple InstrumentScores can reference the same pdfHash',
        () async {
          // Create a score
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Test Score',
                composer: 'Test Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          // Create multiple instrument scores with the same hash
          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_2',
                scoreId: 'score_1',
                instrumentType: 'Violin',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          // Count references
          final references = await (testDb.select(testDb.instrumentScores)
                ..where((is_) =>
                    is_.pdfHash.equals(testPdfHash) & is_.deletedAt.isNull()))
              .get();

          expect(references.length, equals(2));
        },
      );

      test(
        'Reference count decreases when InstrumentScore is deleted',
        () async {
          // Setup
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Test Score',
                composer: 'Test Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_2',
                scoreId: 'score_1',
                instrumentType: 'Violin',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          // Soft delete one
          await (testDb.update(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .write(InstrumentScoresCompanion(deletedAt: Value(DateTime.now())));

          // Count active references
          final references = await (testDb.select(testDb.instrumentScores)
                ..where((is_) =>
                    is_.pdfHash.equals(testPdfHash) & is_.deletedAt.isNull()))
              .get();

          expect(references.length, equals(1));
        },
      );

      test(
        'Reference count is zero when all InstrumentScores are deleted',
        () async {
          // Setup
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Test Score',
                composer: 'Test Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          // Soft delete it
          await (testDb.update(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .write(InstrumentScoresCompanion(deletedAt: Value(DateTime.now())));

          // Count active references
          final references = await (testDb.select(testDb.instrumentScores)
                ..where((is_) =>
                    is_.pdfHash.equals(testPdfHash) & is_.deletedAt.isNull()))
              .get();

          expect(references.length, equals(0));
        },
      );
    });

    group('Cross-Scope Reference Counting', () {
      test(
        'Same pdfHash can be referenced by both user and team scopes',
        () async {
          // Create user score
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'user_score_1',
                title: 'User Score',
                composer: 'Composer',
                scopeType: const Value('user'),
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          // Create team score
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'team_score_1',
                title: 'Team Score',
                composer: 'Composer',
                scopeType: const Value('team'),
                scopeId: 42,
                createdAt: DateTime.now(),
              ));

          // User instrument score with hash
          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_user_1',
                scoreId: 'user_score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          // Team instrument score with SAME hash (deduplication)
          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_team_1',
                scoreId: 'team_score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          // Count ALL references (across scopes)
          final allReferences = await (testDb.select(testDb.instrumentScores)
                ..where((is_) =>
                    is_.pdfHash.equals(testPdfHash) & is_.deletedAt.isNull()))
              .get();

          expect(allReferences.length, equals(2));

          // Verify one is user scope, one is team scope
          final userRef = allReferences.firstWhere(
            (r) => r.id == 'is_user_1',
          );
          final teamRef = allReferences.firstWhere(
            (r) => r.id == 'is_team_1',
          );

          expect(userRef.scoreId, equals('user_score_1'));
          expect(teamRef.scoreId, equals('team_score_1'));
        },
      );

      test(
        'Deleting user reference keeps team reference intact',
        () async {
          // Setup
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'user_score_1',
                title: 'User Score',
                composer: 'Composer',
                scopeType: const Value('user'),
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'team_score_1',
                title: 'Team Score',
                composer: 'Composer',
                scopeType: const Value('team'),
                scopeId: 42,
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_user_1',
                scoreId: 'user_score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_team_1',
                scoreId: 'team_score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                createdAt: DateTime.now(),
              ));

          // Delete user reference
          await (testDb.update(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_user_1')))
              .write(InstrumentScoresCompanion(deletedAt: Value(DateTime.now())));

          // Count active references - should still have 1 (team)
          final references = await (testDb.select(testDb.instrumentScores)
                ..where((is_) =>
                    is_.pdfHash.equals(testPdfHash) & is_.deletedAt.isNull()))
              .get();

          expect(references.length, equals(1));
          expect(references.first.id, equals('is_team_1'));
        },
      );
    });

    group('PDF Hash Deduplication', () {
      test(
        'Different InstrumentScores with same pdfHash share the same file',
        () async {
          // Create scores
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Score 1',
                composer: 'Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_2',
                title: 'Score 2',
                composer: 'Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          // Both use same hash
          final pdfPath = p.join(tempDir.path, '$testPdfHash.pdf');

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                pdfPath: Value(pdfPath),
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_2',
                scoreId: 'score_2',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                pdfPath: Value(pdfPath),
                createdAt: DateTime.now(),
              ));

          // Both should point to same pdfPath
          final is1 = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .getSingle();
          final is2 = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_2')))
              .getSingle();

          expect(is1.pdfHash, equals(is2.pdfHash));
          expect(is1.pdfPath, equals(is2.pdfPath));
        },
      );

      test(
        'Different pdfHash means different files',
        () async {
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Score 1',
                composer: 'Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          final pdfPath1 = p.join(tempDir.path, '$testPdfHash.pdf');
          final pdfPath2 = p.join(tempDir.path, '$testPdfHash2.pdf');

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                pdfPath: Value(pdfPath1),
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_2',
                scoreId: 'score_1',
                instrumentType: 'Violin',
                pdfHash: const Value(testPdfHash2),
                pdfPath: Value(pdfPath2),
                createdAt: DateTime.now(),
              ));

          final is1 = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .getSingle();
          final is2 = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_2')))
              .getSingle();

          expect(is1.pdfHash, isNot(equals(is2.pdfHash)));
          expect(is1.pdfPath, isNot(equals(is2.pdfPath)));
        },
      );
    });

    group('PDF Sync Status', () {
      test(
        'pdfSyncStatus starts as pending for new records',
        () async {
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Test Score',
                composer: 'Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                pdfSyncStatus: const Value('pending'),
                createdAt: DateTime.now(),
              ));

          final record = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .getSingle();

          expect(record.pdfSyncStatus, equals('pending'));
        },
      );

      test(
        'pdfSyncStatus updates to synced after upload',
        () async {
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Test Score',
                composer: 'Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                pdfSyncStatus: const Value('pending'),
                createdAt: DateTime.now(),
              ));

          // Simulate upload completion
          await (testDb.update(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .write(const InstrumentScoresCompanion(
            pdfSyncStatus: Value('synced'),
          ));

          final record = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .getSingle();

          expect(record.pdfSyncStatus, equals('synced'));
        },
      );

      test(
        'pdfSyncStatus set to needsDownload after pull',
        () async {
          await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
                id: 'score_1',
                title: 'Test Score',
                composer: 'Composer',
                scopeId: 1,
                createdAt: DateTime.now(),
              ));

          // Simulates a record pulled from server (has hash but no local path)
          await testDb
              .into(testDb.instrumentScores)
              .insert(InstrumentScoresCompanion.insert(
                id: 'is_1',
                scoreId: 'score_1',
                instrumentType: 'Piano',
                pdfHash: const Value(testPdfHash),
                pdfSyncStatus: const Value('needsDownload'),
                createdAt: DateTime.now(),
              ));

          final record = await (testDb.select(testDb.instrumentScores)
                ..where((is_) => is_.id.equals('is_1')))
              .getSingle();

          expect(record.pdfSyncStatus, equals('needsDownload'));
          expect(record.pdfPath, isNull);
        },
      );
    });
  });

  group('Database deleteAllLocalPdfFiles', () {
    late AppDatabase testDb;
    late Directory tempDir;

    setUp(() async {
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('pdf_delete_test_');
    });

    tearDown(() async {
      await testDb.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'deleteAllLocalPdfFiles deletes all PDF files from disk',
      () async {
        // Create test PDF files
        final pdf1 = File(p.join(tempDir.path, 'test1.pdf'));
        final pdf2 = File(p.join(tempDir.path, 'test2.pdf'));
        await pdf1.writeAsString('PDF content 1');
        await pdf2.writeAsString('PDF content 2');

        // Insert records with pdfPath
        await testDb.into(testDb.scores).insert(ScoresCompanion.insert(
              id: 'score_1',
              title: 'Test Score',
              composer: 'Composer',
              scopeId: 1,
              createdAt: DateTime.now(),
            ));

        await testDb
            .into(testDb.instrumentScores)
            .insert(InstrumentScoresCompanion.insert(
              id: 'is_1',
              scoreId: 'score_1',
              instrumentType: 'Piano',
              pdfPath: Value(pdf1.path),
              createdAt: DateTime.now(),
            ));

        await testDb
            .into(testDb.instrumentScores)
            .insert(InstrumentScoresCompanion.insert(
              id: 'is_2',
              scoreId: 'score_1',
              instrumentType: 'Violin',
              pdfPath: Value(pdf2.path),
              createdAt: DateTime.now(),
            ));

        // Verify files exist
        expect(await pdf1.exists(), isTrue);
        expect(await pdf2.exists(), isTrue);

        // Delete all PDF files
        await testDb.deleteAllLocalPdfFiles();

        // Verify files are deleted
        expect(await pdf1.exists(), isFalse);
        expect(await pdf2.exists(), isFalse);
      },
    );
  });
}
