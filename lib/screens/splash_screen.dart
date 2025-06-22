import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 80),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/dogimage.png', // Updated image path
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.2)
                                .animate(_heartController),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    offset: const Offset(0, 2),
                                    blurRadius: 3.84,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 24,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .scale(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: const Duration(milliseconds: 800)),
                    const SizedBox(height: 40),
                    const Text(
                      'We provide',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .moveY(
                          begin: 50,
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        )
                        .fadeIn(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                        ),
                    const SizedBox(height: 15),
                    const Text(
                      '24hr location tracking & health\nupdates\nOn time feeding',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xE6FFFFFF),
                        height: 1.5,
                      ),
                    )
                        .animate()
                        .moveY(
                          begin: 30,
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        )
                        .fadeIn(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 600),
                        ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
                child: ElevatedButton(
                  onPressed: _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Color(0xFF667EEA),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 900),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;

  const FeatureItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 30),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 91, 195, 226),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xE6FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
