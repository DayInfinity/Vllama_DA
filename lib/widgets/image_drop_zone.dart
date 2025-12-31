import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class ImageDropZone extends StatefulWidget {
  final File? file;
  final VoidCallback onPick;
  final ValueChanged<File> onFileSelected;

  const ImageDropZone({
    super.key,
    required this.file,
    required this.onPick,
    required this.onFileSelected,
  });

  @override
  State<ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<ImageDropZone> {
  bool _dragging = false;

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = _dragging ? cs.primary : cs.outlineVariant;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) {
        setState(() => _dragging = false);
        if (detail.files.isEmpty) return;
        final path = detail.files.first.path;
        if (path.isEmpty) return;
        if (!_isImagePath(path)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please drop an image file (png/jpg/webp/bmp).')),
          );
          return;
        }
        widget.onFileSelected(File(path));
      },
      child: InkWell(
        onTap: widget.onPick,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: widget.file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: cs.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Drop an image here, or click to select',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PNG / JPG / WEBP / BMP',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                )
              : Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.file!,
                        width: 140,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Selected image',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.file!.path.split(Platform.pathSeparator).last,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: widget.onPick,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Choose another'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


