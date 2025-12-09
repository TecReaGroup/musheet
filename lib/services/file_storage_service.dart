import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for managing PDF files and thumbnails in the local file system
/// Uses path_provider to get the application documents directory
class FileStorageService {
  static const String _pdfFolderName = 'pdfs';
  static const String _thumbnailSuffix = '_thumb.jpg';
  static const String _cacheFolderName = 'cache';
  static const String _tempPdfsFolderName = 'temp_pdfs';

  String? _basePath;

  /// Get the base path for file storage
  Future<String> get basePath async {
    if (_basePath != null) return _basePath!;
    
    final directory = await getApplicationDocumentsDirectory();
    _basePath = directory.path;
    return _basePath!;
  }

  /// Get the pdfs directory path
  Future<String> get pdfDirectoryPath async {
    final base = await basePath;
    return p.join(base, _pdfFolderName);
  }

  /// Get the cache directory path
  Future<String> get cacheDirectoryPath async {
    final base = await basePath;
    return p.join(base, _cacheFolderName);
  }

  /// Get the temp pdfs directory path
  Future<String> get tempPdfsDirectoryPath async {
    final cache = await cacheDirectoryPath;
    return p.join(cache, _tempPdfsFolderName);
  }

  /// Ensure all required directories exist
  Future<void> ensureDirectoriesExist() async {
    final pdfDir = Directory(await pdfDirectoryPath);
    final cacheDir = Directory(await cacheDirectoryPath);
    final tempPdfsDir = Directory(await tempPdfsDirectoryPath);

    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    if (!await tempPdfsDir.exists()) {
      await tempPdfsDir.create(recursive: true);
    }
  }

  /// Get the directory for a specific score's PDFs
  Future<String> getScorePdfDirectory(String scoreId) async {
    final pdfDir = await pdfDirectoryPath;
    final scoreDir = p.join(pdfDir, scoreId);
    
    final directory = Directory(scoreDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return scoreDir;
  }

  /// Get the path for a PDF file
  Future<String> getPdfPath(String scoreId, String instrumentScoreId) async {
    final scoreDir = await getScorePdfDirectory(scoreId);
    return p.join(scoreDir, '$instrumentScoreId.pdf');
  }

  /// Get the path for a thumbnail
  Future<String> getThumbnailPath(String scoreId, String instrumentScoreId) async {
    final scoreDir = await getScorePdfDirectory(scoreId);
    return p.join(scoreDir, '$instrumentScoreId$_thumbnailSuffix');
  }

  /// Copy a PDF file to the app's storage
  /// Returns the path to the stored PDF
  Future<String> storePdf({
    required String sourceFilePath,
    required String scoreId,
    required String instrumentScoreId,
  }) async {
    await ensureDirectoriesExist();
    
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourceFilePath);
    }

    final destinationPath = await getPdfPath(scoreId, instrumentScoreId);
    
    // Copy the file
    await sourceFile.copy(destinationPath);
    
    return destinationPath;
  }

  /// Store a thumbnail image
  /// Returns the path to the stored thumbnail
  Future<String> storeThumbnail({
    required List<int> imageBytes,
    required String scoreId,
    required String instrumentScoreId,
  }) async {
    await ensureDirectoriesExist();
    
    final thumbnailPath = await getThumbnailPath(scoreId, instrumentScoreId);
    final thumbnailFile = File(thumbnailPath);
    
    await thumbnailFile.writeAsBytes(imageBytes);
    
    return thumbnailPath;
  }

  /// Delete a PDF file
  Future<void> deletePdf(String scoreId, String instrumentScoreId) async {
    final pdfPath = await getPdfPath(scoreId, instrumentScoreId);
    final pdfFile = File(pdfPath);
    
    if (await pdfFile.exists()) {
      await pdfFile.delete();
    }
  }

  /// Delete a thumbnail
  Future<void> deleteThumbnail(String scoreId, String instrumentScoreId) async {
    final thumbnailPath = await getThumbnailPath(scoreId, instrumentScoreId);
    final thumbnailFile = File(thumbnailPath);
    
    if (await thumbnailFile.exists()) {
      await thumbnailFile.delete();
    }
  }

  /// Delete all files for an instrument score
  Future<void> deleteInstrumentScoreFiles(
      String scoreId, String instrumentScoreId) async {
    await deletePdf(scoreId, instrumentScoreId);
    await deleteThumbnail(scoreId, instrumentScoreId);
  }

  /// Delete all files for a score
  Future<void> deleteScoreFiles(String scoreId) async {
    final scoreDir = await getScorePdfDirectory(scoreId);
    final directory = Directory(scoreDir);
    
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  /// Check if a PDF file exists
  Future<bool> pdfExists(String scoreId, String instrumentScoreId) async {
    final pdfPath = await getPdfPath(scoreId, instrumentScoreId);
    return File(pdfPath).exists();
  }

  /// Check if a thumbnail exists
  Future<bool> thumbnailExists(String scoreId, String instrumentScoreId) async {
    final thumbnailPath = await getThumbnailPath(scoreId, instrumentScoreId);
    return File(thumbnailPath).exists();
  }

  /// Get the file size of a PDF
  Future<int?> getPdfFileSize(String scoreId, String instrumentScoreId) async {
    final pdfPath = await getPdfPath(scoreId, instrumentScoreId);
    final file = File(pdfPath);
    
    if (await file.exists()) {
      return await file.length();
    }
    return null;
  }

  /// Copy a PDF to a temporary location for sharing
  Future<String> copyPdfToTemp(String scoreId, String instrumentScoreId) async {
    final sourcePath = await getPdfPath(scoreId, instrumentScoreId);
    final tempDir = await tempPdfsDirectoryPath;
    final tempPath = p.join(tempDir, '$instrumentScoreId.pdf');
    
    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(tempPath);
    }
    
    return tempPath;
  }

  /// Clear the temporary PDFs cache
  Future<void> clearTempCache() async {
    final tempDir = Directory(await tempPdfsDirectoryPath);
    
    if (await tempDir.exists()) {
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  /// Get the total storage used by PDFs
  Future<int> getTotalStorageUsed() async {
    final pdfDir = Directory(await pdfDirectoryPath);
    int totalSize = 0;
    
    if (await pdfDir.exists()) {
      await for (final entity in pdfDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    
    return totalSize;
  }

  /// Get storage used by a specific score
  Future<int> getScoreStorageUsed(String scoreId) async {
    final scoreDir = Directory(await getScorePdfDirectory(scoreId));
    int totalSize = 0;
    
    if (await scoreDir.exists()) {
      await for (final entity in scoreDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    
    return totalSize;
  }

  /// List all stored score IDs
  Future<List<String>> listStoredScoreIds() async {
    final pdfDir = Directory(await pdfDirectoryPath);
    final scoreIds = <String>[];
    
    if (await pdfDir.exists()) {
      await for (final entity in pdfDir.list()) {
        if (entity is Directory) {
          scoreIds.add(p.basename(entity.path));
        }
      }
    }
    
    return scoreIds;
  }

  /// Get the absolute path from a relative path stored in the database
  Future<String> getAbsolutePath(String relativePath) async {
    final base = await basePath;
    return p.join(base, relativePath);
  }

  /// Get the relative path for storage in the database
  Future<String> getRelativePath(String absolutePath) async {
    final base = await basePath;
    if (absolutePath.startsWith(base)) {
      return absolutePath.substring(base.length + 1);
    }
    return absolutePath;
  }
}