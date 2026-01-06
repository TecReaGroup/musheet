import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:share_plus/share_plus.dart';

import '../models/annotation.dart';
import '../widgets/common_widgets.dart';

/// Helper class to store margin values for all four sides
class _PageMargins {
  final double left;
  final double right;
  final double top;
  final double bottom;

  const _PageMargins({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
  });

  bool get hasMargins => left > 0 || right > 0 || top > 0 || bottom > 0;
}

/// Service for exporting PDF with annotations overlaid
/// Uses hybrid approach: PDF background stays vector, annotations rendered as transparent PNG overlay
class PdfExportService {
  /// Export PDF with annotations and share via share_plus
  ///
  /// [pdfPath] - Path to the original PDF file
  /// [annotations] - Map of page number to list of annotations
  /// [title] - Title for the exported file
  /// [previewSize] - The size used during preview for proper scaling
  static Future<void> exportAndShare({
    required String pdfPath,
    required Map<int, List<Annotation>> annotations,
    required String title,
    required BuildContext context,
    Size? previewSize,
  }) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final exportedPath = await _exportPdfWithAnnotations(
        pdfPath: pdfPath,
        annotations: annotations,
        title: title,
        previewSize: previewSize,
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Share the exported PDF
      if (Platform.isAndroid) {
        // Use platform channel to share with FLAG_ACTIVITY_NEW_TASK
        const channel = MethodChannel('com.example.musheet/share');
        await channel.invokeMethod('shareFileInNewTask', {
          'filePath': exportedPath,
          'mimeType': 'application/pdf',
          'title': 'Share PDF',
        });
      } else {
        // iOS and other platforms use share_plus
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(exportedPath)],
            title: '$title.pdf',
          ),
        );
      }

      // Clean up temp file after sharing
      Future.delayed(const Duration(minutes: 5), () {
        final file = File(exportedPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
        AppToast.error(context, 'Export failed: $e');
      }
    }
  }

  /// Calculate the actual PDF display area within preview (maintaining aspect ratio)
  static ({double width, double height, double offsetX, double offsetY}) _calculatePdfDisplayArea(
    Size previewSize,
    double pageWidth,
    double pageHeight,
  ) {
    final pdfAspectRatio = pageWidth / pageHeight;
    final previewAspectRatio = previewSize.width / previewSize.height;

    double actualWidth, actualHeight;
    double offsetX = 0, offsetY = 0;

    if (pdfAspectRatio > previewAspectRatio) {
      // PDF is wider - fit to width, letterbox top/bottom
      actualWidth = previewSize.width;
      actualHeight = previewSize.width / pdfAspectRatio;
      offsetY = (previewSize.height - actualHeight) / 2;
    } else {
      // PDF is taller - fit to height, pillarbox left/right
      actualHeight = previewSize.height;
      actualWidth = previewSize.height * pdfAspectRatio;
      offsetX = (previewSize.width - actualWidth) / 2;
    }

    return (width: actualWidth, height: actualHeight, offsetX: offsetX, offsetY: offsetY);
  }

  /// Calculate required margins based on annotation overflow across all pages
  /// Returns margins as ratios relative to PDF page size
  static _PageMargins _calculateRequiredMargins({
    required Map<int, List<Annotation>> annotations,
    required Size previewSize,
    required double pageWidth,
    required double pageHeight,
  }) {
    if (annotations.isEmpty) {
      return const _PageMargins();
    }

    final displayArea = _calculatePdfDisplayArea(previewSize, pageWidth, pageHeight);

    // Track min/max relative coordinates across all pages
    // 0-1 range means within PDF bounds
    double minX = 0;
    double maxX = 1;
    double minY = 0;
    double maxY = 1;

    for (final pageAnnotations in annotations.values) {
      for (final annotation in pageAnnotations) {
        if (annotation.type == 'draw' && annotation.points != null) {
          final points = annotation.points!;
          for (int i = 0; i < points.length; i += 2) {
            if (i + 1 < points.length) {
              final normalizedX = points[i];
              final normalizedY = points[i + 1];

              // Convert to relative PDF coordinates
              final previewX = normalizedX * previewSize.width;
              final previewY = normalizedY * previewSize.height;
              final relativeX = (previewX - displayArea.offsetX) / displayArea.width;
              final relativeY = (previewY - displayArea.offsetY) / displayArea.height;

              minX = math.min(minX, relativeX);
              maxX = math.max(maxX, relativeX);
              minY = math.min(minY, relativeY);
              maxY = math.max(maxY, relativeY);
            }
          }
        }
      }
    }

    // Calculate margins as ratios (negative minX means left overflow, etc.)
    // Add small padding for stroke width
    const strokePadding = 0.02; // 2% padding for stroke width

    return _PageMargins(
      left: minX < 0 ? (-minX + strokePadding) : 0,
      right: maxX > 1 ? (maxX - 1 + strokePadding) : 0,
      top: minY < 0 ? (-minY + strokePadding) : 0,
      bottom: maxY > 1 ? (maxY - 1 + strokePadding) : 0,
    );
  }

  /// Export PDF with annotations overlaid using hybrid approach
  static Future<String> _exportPdfWithAnnotations({
    required String pdfPath,
    required Map<int, List<Annotation>> annotations,
    required String title,
    Size? previewSize,
  }) async {
    // Open the original PDF using pdfrx
    final document = await pdfrx.PdfDocument.openFile(pdfPath);
    final pageCount = document.pages.length;

    // Get first page dimensions for margin calculation (assume all pages same size)
    final firstPage = document.pages[0];
    final pageWidth = firstPage.width;
    final pageHeight = firstPage.height;

    // Calculate required margins based on annotation overflow
    _PageMargins margins = const _PageMargins();
    if (previewSize != null && previewSize.width > 0 && annotations.isNotEmpty) {
      margins = _calculateRequiredMargins(
        annotations: annotations,
        previewSize: previewSize,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );
    }

    // Calculate new page dimensions with margins
    final marginLeftPx = margins.left * pageWidth;
    final marginRightPx = margins.right * pageWidth;
    final marginTopPx = margins.top * pageHeight;
    final marginBottomPx = margins.bottom * pageHeight;

    final newPageWidth = pageWidth + marginLeftPx + marginRightPx;
    final newPageHeight = pageHeight + marginTopPx + marginBottomPx;

    // Create new PDF document using pdf package
    final pdf = pw.Document();

    // Use 3x scale for better quality
    const scale = 3.0;

    // Process each page
    for (int pageNum = 1; pageNum <= pageCount; pageNum++) {
      final page = document.pages[pageNum - 1];
      final currentPageWidth = page.width;
      final currentPageHeight = page.height;

      final renderWidth = currentPageWidth * scale;
      final renderHeight = currentPageHeight * scale;

      // Render original PDF page to image (for background)
      final pdfImage = await page.render(
        fullWidth: renderWidth,
        fullHeight: renderHeight,
        backgroundColor: Colors.white.toARGB32(),
      );

      if (pdfImage == null) continue;

      final pdfImageData = await pdfImage.createImage();
      final pdfByteData = await pdfImageData.toByteData(format: ui.ImageByteFormat.png);

      if (pdfByteData == null) continue;

      final pdfPngBytes = pdfByteData.buffer.asUint8List();

      // Get annotations for this page
      final pageAnnotations = annotations[pageNum] ?? [];

      // Render annotations as transparent PNG using Flutter Canvas
      Uint8List? annotationPngBytes;
      if (pageAnnotations.isNotEmpty && previewSize != null && previewSize.width > 0) {
        final displayArea = _calculatePdfDisplayArea(previewSize, currentPageWidth, currentPageHeight);

        // Calculate stroke scale: from preview actual size to render size
        final strokeScale = renderWidth / displayArea.width;

        // New render dimensions including margins
        final newRenderWidth = newPageWidth * scale;
        final newRenderHeight = newPageHeight * scale;
        final marginLeftRender = marginLeftPx * scale;
        final marginTopRender = marginTopPx * scale;

        final annotationImage = await _renderAnnotationsToImage(
          pageAnnotations,
          renderWidth,
          renderHeight,
          newRenderWidth,
          newRenderHeight,
          marginLeftRender,
          marginTopRender,
          previewSize,
          Size(displayArea.width, displayArea.height),
          Offset(displayArea.offsetX, displayArea.offsetY),
          strokeScale,
        );

        final annotationByteData = await annotationImage.toByteData(format: ui.ImageByteFormat.png);
        if (annotationByteData != null) {
          annotationPngBytes = annotationByteData.buffer.asUint8List();
        }
      }

      // Create PDF page with background and annotation overlay
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(newPageWidth, newPageHeight),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // White background for the entire page (including margins)
                pw.Positioned.fill(
                  child: pw.Container(color: PdfColors.white),
                ),
                // Original PDF page positioned with margin offset
                pw.Positioned(
                  left: marginLeftPx,
                  top: marginTopPx,
                  right: marginRightPx,
                  bottom: marginBottomPx,
                  child: pw.Image(
                    pw.MemoryImage(pdfPngBytes),
                    fit: pw.BoxFit.fill,
                  ),
                ),
                // Annotations overlay as transparent PNG (covers entire new page)
                if (annotationPngBytes != null)
                  pw.Positioned.fill(
                    child: pw.Image(
                      pw.MemoryImage(annotationPngBytes),
                      fit: pw.BoxFit.fill,
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final outputPath = '${tempDir.path}/${sanitizedTitle}_annotated.pdf';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(await pdf.save());

    // Clean up
    document.dispose();

    return outputPath;
  }

  /// Render annotations to a transparent PNG image using Flutter Canvas
  ///
  /// [annotations] - List of annotations to render
  /// [pdfRenderWidth], [pdfRenderHeight] - Original PDF render size (PDF size * scale)
  /// [canvasWidth], [canvasHeight] - Total canvas size including margins
  /// [marginLeft], [marginTop] - Margin offsets in render coordinates
  /// [previewSize] - The full preview container size
  /// [actualPreviewSize] - The actual PDF display area within preview (maintaining aspect ratio)
  /// [previewOffset] - Offset of PDF display area within preview container
  /// [strokeScale] - Scale factor for stroke width
  static Future<ui.Image> _renderAnnotationsToImage(
    List<Annotation> annotations,
    double pdfRenderWidth,
    double pdfRenderHeight,
    double canvasWidth,
    double canvasHeight,
    double marginLeft,
    double marginTop,
    Size previewSize,
    Size actualPreviewSize,
    Offset previewOffset,
    double strokeScale,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw annotations using the same logic as _IntegratedAnnotationPainter
    for (final annotation in annotations) {
      if (annotation.type == 'draw' && annotation.points != null) {
        final paint = Paint()
          ..color = Color(int.parse(annotation.color.replaceFirst('#', '0xFF')))
          ..strokeWidth = annotation.width * strokeScale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final points = annotation.points!;
        if (points.length >= 2) {
          final path = Path();

          // Transform normalized coordinates to render coordinates
          // 1. Denormalize to preview coordinates
          // 2. Adjust for offset (if PDF doesn't fill entire preview)
          // 3. Scale to PDF render size
          // 4. Add margin offset

          double transformX(double normalizedX) {
            final previewX = normalizedX * previewSize.width;
            final relativeX = (previewX - previewOffset.dx) / actualPreviewSize.width;
            // Position relative to PDF area, then add margin offset
            return relativeX * pdfRenderWidth + marginLeft;
          }

          double transformY(double normalizedY) {
            final previewY = normalizedY * previewSize.height;
            final relativeY = (previewY - previewOffset.dy) / actualPreviewSize.height;
            return relativeY * pdfRenderHeight + marginTop;
          }

          path.moveTo(
            transformX(points[0]),
            transformY(points[1]),
          );

          for (int i = 2; i < points.length; i += 2) {
            if (i + 1 < points.length) {
              final x = transformX(points[i]);
              final y = transformY(points[i + 1]);

              if (i + 3 < points.length) {
                final x2 = transformX(points[i + 2]);
                final y2 = transformY(points[i + 3]);
                final controlX = (x + x2) / 2;
                final controlY = (y + y2) / 2;
                path.quadraticBezierTo(x, y, controlX, controlY);
              } else {
                path.lineTo(x, y);
              }
            }
          }
          canvas.drawPath(path, paint);
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());

    return image;
  }
}
