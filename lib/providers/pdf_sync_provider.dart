import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_provider.dart';

/// PDF download status for UI
enum PdfDownloadStatus {
  idle,
  downloading,
  completed,
  error,
}

/// State for PDF download operation
class PdfDownloadState {
  final PdfDownloadStatus status;
  final String? filePath;
  final String? errorMessage;

  const PdfDownloadState({
    this.status = PdfDownloadStatus.idle,
    this.filePath,
    this.errorMessage,
  });
}

/// Function to download PDF for an instrument score
/// Uses the sync service directly
/// Returns the file path if successful, null otherwise
Future<String?> downloadPdfForScore(Ref ref, String instrumentScoreId) async {
  final syncServiceAsync = ref.read(syncServiceProvider);
  final syncService = switch (syncServiceAsync) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (syncService == null) {
    return null;
  }

  try {
    return await syncService.downloadPdfForInstrumentScore(instrumentScoreId);
  } catch (e) {
    return null;
  }
}

/// Helper function to check if PDF needs download
Future<bool> needsPdfDownload(Ref ref, String instrumentScoreId) async {
  final syncServiceAsync = ref.read(syncServiceProvider);
  final syncService = switch (syncServiceAsync) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (syncService == null) return false;
  return await syncService.needsPdfDownload(instrumentScoreId);
}

/// Helper function to mark PDF as pending upload
Future<void> markPdfPendingUpload(Ref ref, String instrumentScoreId) async {
  final syncServiceAsync = ref.read(syncServiceProvider);
  final syncService = switch (syncServiceAsync) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (syncService == null) return;
  await syncService.markPdfPendingUpload(instrumentScoreId);
}
