import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:image/image.dart' as img;
import '../../utils/icon_mappings.dart';

/// Screen for cropping avatar images with custom UI
class AvatarCropScreen extends StatefulWidget {
  final File imageFile;

  const AvatarCropScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  late CustomImageCropController _cropController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cropController = CustomImageCropController();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _cropController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final croppedImage = await _cropController.onCropImage();
      if (croppedImage == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to crop image')),
          );
        }
        return;
      }

      // Decode and resize to 512x512 for avatar
      final decodedImage = img.decodeImage(croppedImage.bytes);
      if (decodedImage == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to decode image')),
          );
        }
        return;
      }

      final resized = img.copyResize(
        decodedImage,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.linear,
      );

      // Encode as PNG
      final Uint8List bytes = Uint8List.fromList(img.encodePng(resized));

      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Full screen crop area
          Positioned.fill(
            child: CustomImageCrop(
              cropController: _cropController,
              image: FileImage(widget.imageFile),
              shape: CustomCropShape.Circle,
              cropPercentage: 0.85,
              canRotate: false,
              canScale: true,
              canMove: true,
              forceInsideCropArea: true,
              imageFit: CustomImageFit.fitVisibleSpace,
              customProgressIndicator: const CircularProgressIndicator(
                color: Colors.white,
              ),
              overlayColor: Colors.black.withValues(alpha: 0.7),
              pathPaint: Paint()
                ..color = Colors.white
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
            ),
          ),

          // Top bar with back and done buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel button
                    IconButton(
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        AppIcons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Title
                    const Text(
                      'Move and Scale',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // Done button
                    _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: _cropAndSave,
                            icon: const Icon(
                              AppIcons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
