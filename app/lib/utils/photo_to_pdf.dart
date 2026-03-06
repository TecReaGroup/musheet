import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Utility class for converting photos/images to PDF format
class PhotoToPdfConverter {
  /// Supported image extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
  ];

  /// Check if a file is a supported image format
  static bool isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return supportedImageExtensions.contains(extension);
  }

  /// Check if a file is a PDF
  static bool isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Convert a single image file to PDF
  /// Returns the path to the generated PDF file
  static Future<String> convertImageToPdf(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Read image bytes
    final Uint8List imageBytes = await imageFile.readAsBytes();
    
    // Decode image to get dimensions
    final img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image: $imagePath');
    }

    // Create PDF document
    final pdf = pw.Document();

    // Create image widget for PDF
    final pdfImage = pw.MemoryImage(imageBytes);

    // Calculate page size based on image aspect ratio
    // Use A4 as base, but adjust to fit image proportionally
    final double imageAspectRatio = decodedImage.width / decodedImage.height;
    
    PdfPageFormat pageFormat;
    if (imageAspectRatio > 1) {
      // Landscape image
      pageFormat = PdfPageFormat.a4.landscape;
    } else {
      // Portrait image
      pageFormat = PdfPageFormat.a4.portrait;
    }

    // Add page with image
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(
              pdfImage,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    // Generate output file path
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalFileName = imagePath.split(Platform.pathSeparator).last;
    final baseName = originalFileName.split('.').first;
    final outputPath = '${directory.path}${Platform.pathSeparator}${baseName}_$timestamp.pdf';

    // Save PDF
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(await pdf.save());

    return outputPath;
  }

  /// Convert multiple images to a single PDF (one image per page)
  /// Returns the path to the generated PDF file
  static Future<String> convertMultipleImagesToPdf(
    List<String> imagePaths, {
    String? outputFileName,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception('No images provided');
    }

    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        continue; // Skip missing files
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) {
        continue; // Skip undecodable images
      }

      final pdfImage = pw.MemoryImage(imageBytes);
      final double imageAspectRatio = decodedImage.width / decodedImage.height;
      
      PdfPageFormat pageFormat;
      if (imageAspectRatio > 1) {
        pageFormat = PdfPageFormat.a4.landscape;
      } else {
        pageFormat = PdfPageFormat.a4.portrait;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    // Generate output file path
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = outputFileName ?? 'images_$timestamp';
    final outputPath = '${directory.path}${Platform.pathSeparator}$fileName.pdf';

    // Save PDF
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(await pdf.save());

    return outputPath;
  }

  /// Process a file - if it's an image, convert to PDF; if it's already a PDF, return as-is
  /// Returns the path to the PDF file (either converted or original)
  static Future<String> processFile(String filePath) async {
    if (isPdfFile(filePath)) {
      return filePath;
    }
    
    if (isImageFile(filePath)) {
      return await convertImageToPdf(filePath);
    }
    
    throw Exception('Unsupported file format: $filePath');
  }

  /// Get file type description for UI
  static String getFileTypeDescription(String filePath) {
    if (isPdfFile(filePath)) {
      return 'PDF Document';
    }
    if (isImageFile(filePath)) {
      final extension = filePath.split('.').last.toUpperCase();
      return '$extension Image';
    }
    return 'Unknown';
  }
}