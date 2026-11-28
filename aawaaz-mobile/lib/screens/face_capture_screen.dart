import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Opens the front camera with a live preview and captures one photo.
/// Pops with the photo as a base64 string, or null if cancelled/unavailable.
class FaceCaptureScreen extends StatefulWidget {
  final String title;
  const FaceCaptureScreen({super.key, this.title = 'Face'});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Camera not available — use username & PIN instead.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final shot = await controller.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not capture — please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : controller == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(child: Center(child: CameraPreview(controller))),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _capture,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(60)),
                          icon: _busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.camera_alt),
                          label: const Text('Capture', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
