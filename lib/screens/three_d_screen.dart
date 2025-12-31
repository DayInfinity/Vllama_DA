import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/glb_storage.dart';
import '../services/vllama_api.dart';
import '../widgets/glb_viewer.dart';
import '../widgets/image_drop_zone.dart';
// import '../widgets/log_panel.dart';
import '../services/app_log.dart';

class ThreeDScreen extends StatefulWidget {
  const ThreeDScreen({super.key});

  @override
  State<ThreeDScreen> createState() => _ThreeDScreenState();
}

class _ThreeDScreenState extends State<ThreeDScreen> {
  File? _imageFile;
  File? _glbFile;
  bool _loading = false;
  String? _error;
  String? _username;
  String? _apiKey;
  bool _isApiKeyHidden = true;

  Future<void> _pickImage() async {
    AppLog.add('Pick image: opening file picker');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    AppLog.add('Pick image: selected $path');
    setState(() {
      _imageFile = File(path);
      _glbFile = null;
      _error = null;
    });
  }

  Future<void> _generate() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    if (_username == null || _username!.isEmpty || _apiKey == null || _apiKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your username and API key.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _glbFile = null;
    });

    try {
      AppLog.add('Generate: calling backend…');
      final resp = await VllamaApi.generate3d(
        imageFile: _imageFile!,
        username: _username!,
        apiKey: _apiKey!,
      );
      final glbData = resp['glbData']?.toString();
      if (glbData == null || glbData.isEmpty) {
        throw Exception('Response missing glbData.');
      }
      final fileName = resp['fileName']?.toString();
      final file = await GlbStorage.saveFromBase64(glbBase64: glbData, fileName: fileName);
      if (!mounted) return;
      AppLog.add('Generate: GLB file ready -> ${file.path}');
      setState(() => _glbFile = file);
    } catch (e) {
      if (!mounted) return;
      AppLog.add('Generate: ERROR $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildLeftPanel() {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 16), // Added padding to create gap between scrollbar and items
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '3D Model Generation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload or drop an image, then click Generate 3D. The backend returns a Base64 GLB which we render in-app.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (value) => setState(() => _username = value),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: _isApiKeyHidden,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isApiKeyHidden ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _isApiKeyHidden = !_isApiKeyHidden),
                  ),
                ),
                onChanged: (value) => setState(() => _apiKey = value),
              ),
              const SizedBox(height: 16),
              ImageDropZone(
                file: _imageFile,
                onPick: _pickImage,
                onFileSelected: (f) {
                  setState(() {
                    _imageFile = f;
                    _glbFile = null;
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_loading ? 'Generating…' : 'Generate 3D'),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: cs.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: cs.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _glbFile == null
            ? Container(
                height: 520,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.10),
                      cs.secondary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Your 3D model will appear here',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            : SizedBox(
                height: 520,
                child: GlbViewer(glbFile: _glbFile!),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Model'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1050;
          final padding = EdgeInsets.all(wide ? 20 : 14);
          return Padding(
            padding: padding,
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 420, child: _buildLeftPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRightPanel()),
                    ],
                  )
                : Column(
                    children: [
                      _buildLeftPanel(),
                      const SizedBox(height: 16),
                      _buildRightPanel(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}


