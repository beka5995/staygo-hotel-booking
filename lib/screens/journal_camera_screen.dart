import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class JournalCameraScreen extends StatefulWidget {
  const JournalCameraScreen({super.key, required this.lens});
  final CameraLensDirection lens;

  @override
  State<JournalCameraScreen> createState() => _JournalCameraScreenState();
}

class _JournalCameraScreenState extends State<JournalCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _error;
  bool _taking = false;
  bool _openingSystemCamera = false;
  int _generation = 0;
  Future<void> _released = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  void _release() {
    _generation++;
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      _released = camera.dispose().catchError((Object _) {});
    }
  }

  Future<void> _open() async {
    final generation = ++_generation;
    await _released;
    if (!mounted || generation != _generation) return;

    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _generation) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera is available.');
        return;
      }
      final matching = cameras.where(
        (camera) => camera.lensDirection == widget.lens,
      );
      if (!kIsWeb && matching.isEmpty) {
        setState(() => _error = 'This camera is unavailable on your device.');
        return;
      }
      // Desktop browsers may expose a single webcam with no meaningful lens direction.
      final camera = CameraController(
        matching.firstOrNull ?? cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _camera = camera;
      await camera.initialize();
      if (mounted && generation == _generation) setState(() => _error = null);
    } on CameraException catch (error) {
      if (!mounted || generation != _generation) return;
      _release();
      setState(
        () => _error = error.code.toLowerCase().contains('accessdenied')
            ? 'Camera access was denied. Allow it in camera permissions and try again.'
            : 'Could not start the camera. Check that it is available and try again.',
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _release();
      setState(() => _error = 'Could not start the camera.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb || _openingSystemCamera) return;
    if (state == AppLifecycleState.resumed &&
        _camera == null &&
        _error == null) {
      unawaited(_open());
    } else if (state != AppLifecycleState.resumed && _camera != null) {
      setState(_release);
    }
  }

  Future<void> _take() async {
    final camera = _camera;
    if (camera == null || _taking) return;
    setState(() => _taking = true);
    try {
      final file = await camera.takePicture();
      if (!mounted) return;
      setState(_release);
      await _released;
      if (mounted) Navigator.pop(context, file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not take the photo. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  Future<void> _systemCapture() async {
    _openingSystemCamera = true;
    setState(() => _taking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: widget.lens == CameraLensDirection.front
            ? CameraDevice.front
            : CameraDevice.rear,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (file != null && mounted) Navigator.pop(context, file);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the device camera.')),
        );
      }
    } finally {
      _openingSystemCamera = false;
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final error = _error;
    final title = widget.lens == CameraLensDirection.front
        ? 'Front camera'
        : 'Rear camera';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: error != null
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _taking
                          ? null
                          : () {
                              setState(() => _error = null);
                              unawaited(_open());
                            },
                      child: const Text('Try again'),
                    ),
                    if (!kIsWeb)
                      TextButton(
                        onPressed: _taking ? null : _systemCapture,
                        child: const Text('Open device camera'),
                      ),
                  ],
                ),
              )
            : camera != null && camera.value.isInitialized
            ? CameraPreview(camera)
            : const CircularProgressIndicator(),
      ),
      bottomNavigationBar:
          error == null && camera != null && camera.value.isInitialized
          ? SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _taking ? null : _take,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Capture'),
              ),
            )
          : null,
    );
  }
}
