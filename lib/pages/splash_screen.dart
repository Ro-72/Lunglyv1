import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/video/lunglyi.mp4');

      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Reproducir el video
      await _controller.play();

      // Escuchar cuando el video termine
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToHome();
        }
      });
    } catch (e) {
      // Si hay error cargando el video, navegar directamente
      debugPrint('Error loading video: $e');
      await Future.delayed(const Duration(seconds: 2));
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4d99ed),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
      ),
    );
  }
}
