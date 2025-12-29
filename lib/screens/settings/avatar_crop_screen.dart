import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:image/image.dart' as img;
import '../../theme/app_colors.dart';
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
  }

  @override
  void dispose() {
    _cropController.dispose();
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header - matching settings style
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        AppIcons.chevronLeft,
                        color: AppColors.gray600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Crop Avatar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                    // Confirm button
                    TextButton(
                      onPressed: _isProcessing ? null : _cropAndSave,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue500,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Crop area
          Expanded(
            child: Container(
              color: AppColors.gray50,
              child: CustomImageCrop(
                cropController: _cropController,
                image: FileImage(widget.imageFile),
                shape: CustomCropShape.Circle,
                cropPercentage: 0.8,
                canRotate: true,
                canScale: true,
                canMove: true,
                customProgressIndicator: const CircularProgressIndicator(
                  color: AppColors.blue500,
                ),
                overlayColor: Colors.black.withValues(alpha: 0.5),
                pathPaint: Paint()
                  ..color = AppColors.blue500
                  ..strokeWidth = 2
                  ..style = PaintingStyle.stroke,
              ),
            ),
          ),

          // Bottom controls - white background
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Rotate left
                    _buildControlButton(
                      icon: AppIcons.rotateCcw,
                      label: 'Rotate Left',
                      onTap: () => _cropController.addTransition(
                        CropImageData(angle: -90 * 3.14159 / 180),
                      ),
                    ),
                    // Reset
                    _buildControlButton(
                      icon: AppIcons.refreshCcw,
                      label: 'Reset',
                      onTap: () => _cropController.reset(),
                    ),
                    // Rotate right
                    _buildControlButton(
                      icon: AppIcons.rotateCw,
                      label: 'Rotate Right',
                      onTap: () => _cropController.addTransition(
                        CropImageData(angle: 90 * 3.14159 / 180),
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: _isProcessing ? AppColors.gray300 : AppColors.gray600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _isProcessing ? AppColors.gray300 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
