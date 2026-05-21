import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// The splash screen is the very first screen the user sees.
// It shows the Khaja Attariya brand for 2 seconds.
// Then it checks auth state and navigates accordingly.
// Right now it always goes to home — we add auth check later.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // AnimationController drives the logo fade-in animation.
  // SingleTickerProviderStateMixin provides the ticker
  // that keeps the animation in sync with the screen refresh rate.
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _navigate();
  }

  void _setupAnimation() {
    // The animation runs for 1.2 seconds total
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade from invisible (0.0) to fully visible (1.0)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      // Only runs during the first 60% of the animation duration
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Scale from slightly small (0.8) to full size (1.0)
    // Gives a gentle "pop in" feel to the logo
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Start the animation immediately
    _controller.forward();
  }

  Future<void> _navigate() async {
    // Wait 2.5 seconds total — animation plays then we navigate
    await Future.delayed(const Duration(milliseconds: 2500));

    // mounted check — make sure the widget is still on screen
    // before navigating. If user somehow closed the app mid-splash,
    // this prevents a crash.
    if (!mounted) return;

    // Go to home screen
    // context.go() replaces the current route — user can't go back to splash
    context.go(RouteNames.home);
  }

  @override
  void dispose() {
    // Always dispose AnimationController to free memory
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Splash background is our primary red
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          // AnimatedBuilder rebuilds only this subtree on every animation frame
          // More efficient than calling setState() on every frame
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          // child is built once and reused — not rebuilt on every frame
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // App Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 56,
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              const Text(
                'Khaja Attariya',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline in Nepali
              Text(
                'Mito Khana, Ghar Samma',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.white.withOpacity(0.85),
                ),
              ),

            ],
          ),
        ),
      ),

      // Version number at the bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'v1.0.0',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}