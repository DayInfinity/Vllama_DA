import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_angle/flutter_angle.dart' show Uint8Array;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../services/app_log.dart';

/// In-app GLB viewer using the `three_js` engine.
///
/// Note:
/// - This uses `three_js`'s built-in `ThreeJS` widget which renders into a
///   Flutter `Texture` and supports desktop/mobile without WebView.
/// - The GLB must already be generated/converted by the backend.
class GlbViewer extends StatefulWidget {
  final File glbFile;

  const GlbViewer({super.key, required this.glbFile});

  @override
  State<GlbViewer> createState() => _GlbViewerState();
}

class _GlbViewerState extends State<GlbViewer> {
  late final three.ThreeJS _threeJs;
  three.OrbitControls? _controls;
  three.Object3D? _modelRoot;
  three.Texture? _pointSprite;
  bool _appliedInitialModelRotation = false;

  @override
  void initState() {
    super.initState();
    AppLog.add('Viewer init (glbFile=${widget.glbFile.path})');
    _threeJs = three.ThreeJS(
      onSetupComplete: () {
        AppLog.add('Viewer setup complete');
        if (mounted) setState(() {});
      },
      setup: _setupScene,
      rendererUpdate: _tick,
      settings: three.Settings(
        antialias: true,
        alpha: false,
        // Clamp DPR a bit on desktop so points stay crisp without becoming “washed out”
        // (and without oversampling too hard on high-DPI monitors).
        screenResolution: 1.5,
        // three_js_core expects AARRGGBB (32-bit). Without the alpha byte,
        // colors can look wrong on some platforms.
        clearColor: 0xFFFFFFFF,
        animate: true,
      ),
    );
  }

  void _tick() {
    _controls?.update();
  }

  void _resetView() {
    final root = _modelRoot;
    if (root == null) return;
    _frameToModel(root);
    setState(() {});
  }

  Future<void> _setupScene() async {
    AppLog.add('Viewer setup: creating scene/camera/lights/controls');
    // Scene + camera
    _threeJs.scene = three.Scene();
    // Pure white background.
    // IMPORTANT: `three.Color(r,g,b)` expects 0..1 floats, so use hex helpers.
    _threeJs.scene.background = three.Color.fromHex32(0xFFFFFFFF);

    _threeJs.camera = three.PerspectiveCamera(55, _threeJs.width / _threeJs.height, 0.1, 1000);
    _threeJs.camera.position.setValues(0, 1.0, 3.0);

    // Lights
    final ambient = three.AmbientLight(0xffffff, 0.95);
    _threeJs.scene.add(ambient);
    final dir1 = three.DirectionalLight(0xffffff, 0.9);
    dir1.position.setValues(3, 5, 2);
    _threeJs.scene.add(dir1);
    final dir2 = three.DirectionalLight(0xffffff, 0.35);
    dir2.position.setValues(-3, 2, -2);
    _threeJs.scene.add(dir2);

    // Controls (mouse rotate/zoom/pan)
    _controls = three.OrbitControls(_threeJs.camera, _threeJs.globalKey);
    _controls!.enableDamping = true;
    _controls!.dampingFactor = 0.07;
    // Open3D-like feel:
    // - Left drag: rotate
    // - Wheel / middle: zoom
    // - Shift + drag: pan (prevents "random origin" drift when panning accidentally)
    _controls!.enablePan = true;
    _controls!.enableZoom = true;
    _controls!.enableRotate = true;
    _controls!.rotateSpeed = 1.0;
    _controls!.zoomSpeed = 1.0;
    // Don’t clamp polar too aggressively; users expect full “orbit around object”
    // like Open3D (including reaching steep top/bottom views).
    _controls!.minPolarAngle = 0.0;
    _controls!.maxPolarAngle = math.pi;
    // Disable default right-click pan; require Shift for pan.
    _controls!.mouseButtons['right'] = three.Mouse.rotate;
    _controls!.mouseButtons['left'] = three.Mouse.rotate;
    _controls!.mouseButtons['MIDDLE'] = three.Mouse.dolly;

    // Point sprite (circular) so points look like Open3D splats, not squares.
    _pointSprite ??= _buildPointSpriteTexture();

    // Load GLB model
    await _loadGlb(widget.glbFile);
  }

  three.Texture _buildPointSpriteTexture() {
    // Higher-res sprite prevents “blocky” points when we increase point size.
    const size = 128;
    final data = Uint8Array(size * size * 4);
    const cx = (size - 1) / 2.0;
    const cy = (size - 1) / 2.0;
    const r = size / 2.15;
    const edge = 2.0; // soft edge thickness (in pixels)

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = math.sqrt(dx * dx + dy * dy);
        // Mostly-opaque disk with a small antialiased edge (denser look, less “washed out”).
        // a=1 inside, then fade to 0 over the outer edge region.
        double a = 0.0;
        if (dist <= r - edge) {
          a = 1.0;
        } else if (dist <= r) {
          final t = (dist - (r - edge)) / edge; // 0..1
          a = 1.0 - t;
        }

        final i = (y * size + x) * 4;
        data[i + 0] = 255;
        data[i + 1] = 255;
        data[i + 2] = 255;
        data[i + 3] = (a * 255).clamp(0, 255).toInt();
      }
    }

    final tex = three.DataTexture(
      data,
      size,
      size,
      three.RGBAFormat,
      three.UnsignedByteType,
    );
    tex.magFilter = three.LinearFilter;
    tex.minFilter = three.LinearFilter;
    tex.needsUpdate = true;
    return tex;
  }

  Future<void> _loadGlb(File file) async {
    AppLog.add('Viewer load: ${file.path} (bytes=${await file.length()})');
    // Remove existing
    if (_modelRoot != null) {
      _threeJs.scene.remove(_modelRoot!);
      _modelRoot = null;
    }

    final loader = three.GLTFLoader();
    AppLog.add('GLTFLoader.fromFile()…');
    final data = await loader.fromFile(file);
    if (data == null) {
      throw Exception('Failed to load GLB.');
    }
    AppLog.add('GLTF loaded. scene=${data.scene.type} children=${data.scene.children.length}');

    final root = data.scene;
    _modelRoot = root;

    // Center + scale model to fit view
    _threeJs.scene.add(root);
    _frameToModel(root);
    AppLog.add('Viewer ready (centered+scaled).');
  }

  void _frameToModel(three.Object3D root) {
    // Ensure world matrices are up-to-date before computing bounds.
    root.updateWorldMatrix(true, true);

    // Compute bounds in world space.
    final box = three.BoundingBox().setFromObject(root);
    final center = box.getCenter(three.Vector3());
    final size = box.getSize(three.Vector3());
    final maxDim = [size.x, size.y, size.z].reduce((a, b) => a > b ? a : b);

    // Recentering: move model so its center is at origin.
    root.position.sub(center);

    // Scale: keep model in a reasonable size range for camera controls.
    if (maxDim.isFinite && maxDim > 0) {
      final scale = 2.0 / maxDim;
      root.scale.setValues(scale, scale, scale);
    }

    // Apply a one-time 180° flip around X (matches Open3D rotate((pi,0,0))).
    // Do this AFTER recentering so it rotates around the origin/model center.
    if (!_appliedInitialModelRotation) {
      root.rotation.set(math.pi, 0.0, 0.0);
      _appliedInitialModelRotation = true;
    }

    // Update after transforms.
    root.updateWorldMatrix(true, true);

    // Recompute bounds after recenter+scale.
    final box2 = three.BoundingBox().setFromObject(root);
    final center2 = box2.getCenter(three.Vector3());
    final size2 = box2.getSize(three.Vector3());
    final radius = size2.length * 0.5;
    final safeRadius = (radius.isFinite && radius > 0) ? radius : 1.0;

    // Orbit around the actual model center.
    _controls?.target.setFrom(center2);

    // Improve point-cloud appearance AFTER we know the final scale/camera framing.
    // PointsMaterial.size is in world units when sizeAttenuation=true.
    // If it's too large, points become huge squares ("voxel" look).
    root.traverse((obj) {
      final geom = obj.geometry;
      final colorAttr = geom?.attributes['color'];

      if (colorAttr != null) {
        final sampleN = math.min<int>(8, colorAttr.count);
        double maxC = 0;
        for (int i = 0; i < sampleN; i++) {
          final x = (colorAttr.getX(i) ?? 0).toDouble();
          final y = (colorAttr.getY(i) ?? 0).toDouble();
          final z = (colorAttr.getZ(i) ?? 0).toDouble();
          maxC = math.max(maxC, math.max(x, math.max(y, z)));
        }
        AppLog.add(
          'Vertex colors detected on ${obj.type}: itemSize=${colorAttr.itemSize} '
          'count=${colorAttr.count} normalized=${colorAttr.normalized} '
          'sampleMax=$maxC arrayType=${colorAttr.array.runtimeType}',
        );
        if (maxC > 1.0 && maxC <= 255.0) {
          colorAttr.normalized = true;
          colorAttr.needsUpdate = true;
          AppLog.add('Enabled colorAttr.normalized=true (0..255 -> 0..1)');
        }
      }

      final mat = obj.material;
      if (mat != null && colorAttr != null) {
        mat.vertexColors = true;
      }

      if (obj is three.Points) {
        final pm = obj.material;
        if (pm is three.PointsMaterial) {
          pm.vertexColors = colorAttr != null;
          pm.sizeAttenuation = true;

          // Slightly thicker points (closer to Open3D defaults). If this is still too thin/thick,
          // we can expose it as a UI slider.
          pm.size = math.max(0.0005, safeRadius * 0.028);

          // Use circular sprite to avoid square points.
          pm.map = _pointSprite;
          // Prefer cutout (alphaTest) over blending so the cloud looks denser/less “faded”.
          pm.transparent = false;
          pm.opacity = 1.0;
          pm.alphaTest = 0.02;
          pm.depthWrite = true;

          // Don't tint vertex colors.
          pm.color.setFromHex32(0xFFFFFF);
        }
      }
    });

    // Camera: fit to model and allow close zooming (Open3D-like).
    _threeJs.camera.near = safeRadius / 2000; // much closer (lets you zoom "into" the model)
    _threeJs.camera.far = safeRadius * 500;
    _threeJs.camera.updateProjectionMatrix();

    _threeJs.camera.position.setValues(
      center2.x,
      center2.y + safeRadius * 0.3,
      center2.z + safeRadius * 1.6,
    );

    // Zoom limits: allow zooming *into* the model.
    _controls?.minDistance = safeRadius * 0.002;
    _controls?.maxDistance = safeRadius * 30;
    _controls?.update();
  }

  @override
  void didUpdateWidget(covariant GlbViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glbFile.path != widget.glbFile.path) {
      _loadGlb(widget.glbFile);
    }
  }

  @override
  void dispose() {
    AppLog.add('Viewer dispose');
    _controls?.deactivate();
    _controls?.dispose();
    _threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(child: _threeJs.build()),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _resetView,
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text('Reset View'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


