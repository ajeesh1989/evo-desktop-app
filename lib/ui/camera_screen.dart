import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glitch_garden/controllers/robot_sound_manager.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isReady = false;
  String? _capturedImagePath;
  final RobotSoundManager sound = RobotSoundManager();
  // Optimized Animation Controllers (Lighter than doWhile loops)
  late AnimationController _progressController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();

    sound.init(); // 👈 ADD THIS

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isReady = true);

      // Start the progress ring
      _progressController.forward().then((_) {
        if (_capturedImagePath == null && mounted) _capture();
      });
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // 🔊 PLAY SHUTTER SOUND (BEFORE CAPTURE)
      sound.play('camera'); // or 'shutter' depending on your asset

      final file = await _controller!.takePicture();

      if (mounted) {
        setState(() => _capturedImagePath = file.path);
      }
    } catch (e) {
      debugPrint("Capture Error: $e");
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scanLineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      backgroundColor: Colors.black, // Background of the scaffold
      body: Stack(
        children: [
          // 1. FULL SCREEN IMAGE/PREVIEW (No Cropping)
          Positioned.fill(
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child:
                    _capturedImagePath != null
                        ? Image.file(
                          File(_capturedImagePath!),
                          fit: BoxFit.contain,
                        )
                        : CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. HUD OVERLAYS (Translucent, not Black)
          if (_capturedImagePath == null) _buildLiveHUD(),

          // 3. RESULT UI (Clear View, No Heavy Blur)
          if (_capturedImagePath != null) _buildResultUI(),
        ],
      ),
    );
  }

  Widget _buildLiveHUD() {
    return Stack(
      children: [
        // Moving Scan Line
        AnimatedBuilder(
          animation: _scanLineController,
          builder: (context, child) {
            return Positioned(
              top:
                  MediaQuery.of(context).size.height *
                  _scanLineController.value,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.cyanAccent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Cyber Brackets
        Positioned.fill(child: CustomPaint(painter: HUDPainter())),

        // Progress Shutter
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: _progressController.value,
                          color: Colors.cyanAccent,
                          backgroundColor: Colors.white10,
                          strokeWidth: 3,
                        ),
                      ),
                      const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                "SCANNING OBJECT...",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultUI() {
    return Container(
      // No background color or heavy blur here to keep the photo clear
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                "CAPTURE SUCCESSFUL",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Buttons use a light frost effect only in their small area
          Row(
            children: [
              Expanded(
                child: _actionBtn("DISCARD", Colors.redAccent, () {
                  setState(() => _capturedImagePath = null);
                  _progressController.reset();
                  _progressController.forward().then((_) => _capture());
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionBtn("COMMIT", Colors.cyanAccent, () {
                  Navigator.pop(context, _capturedImagePath);
                }, isPrimary: true),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    Color color,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? color.withOpacity(0.8) : Colors.black45,
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(4), // Angular/Robotic look
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.black : color,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class HUDPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.4)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    const double s = 40; // size
    const double p = 30; // padding

    canvas.drawPath(
      Path()
        ..moveTo(p, p + s)
        ..lineTo(p, p)
        ..lineTo(p + s, p),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - p - s, p)
        ..lineTo(size.width - p, p)
        ..lineTo(size.width - p, p + s),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(p, size.height - p - s)
        ..lineTo(p, size.height - p)
        ..lineTo(p + s, size.height - p),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - p - s, size.height - p)
        ..lineTo(size.width - p, size.height - p)
        ..lineTo(size.width - p, size.height - p - s),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
