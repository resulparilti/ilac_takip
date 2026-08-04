import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ilac_takip/core/platform/medicine_image.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class PhotoPickerWidget extends StatelessWidget {
  const PhotoPickerWidget({
    super.key,
    this.photoPath,
    required this.onChanged,
  });

  final String? photoPath;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file != null) onChanged(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = medicineImageProvider(photoPath);
    final hasPhoto = image != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('İlaç fotoğrafı', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
              image: hasPhoto
                  ? DecorationImage(image: image, fit: BoxFit.cover)
                  : null,
            ),
            child: hasPhoto
                ? Align(
                    alignment: Alignment.topRight,
                    child: IconButton.filledTonal(
                      onPressed: () => onChanged(null),
                      icon: const Icon(Icons.close),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Fotoğraf ekle',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
