import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monifly/core/constants/gradients.dart';
import 'package:monifly/core/constants/app_constants.dart';
import 'package:monifly/core/constants/strings.dart';
import 'package:monifly/data/datasources/local/shared_prefs_helper.dart';
import 'package:monifly/data/datasources/remote/supabase_client.dart';
import 'package:monifly/core/services/biometric_service.dart';
import 'package:monifly/data/providers/navigation_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _flyController;
  late AnimationController _fadeController;
  late Animation<Offset> _flyAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _flyAnimation =
        Tween<Offset>(begin: const Offset(-1.5, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _flyController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) _navigate();
  }

  void _navigate() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user != null) {
      final biometricEnabled = SharedPrefsHelper.getBool(
        AppConstants.keyBiometricEnabled,
      );
      if (biometricEnabled) {
        final biometricService = BiometricService();
        final authenticated = await biometricService.authenticate();
        if (!authenticated) {
          // If fail, go to login (force re-login)
          if (mounted)
            Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
          return;
        }
      }
      if (mounted) {
        ref.read(navigationIndexProvider.notifier).state = 0;
        Navigator.pushReplacementNamed(context, AppConstants.routeMain);
      }
    } else {
      final onboardingDone = SharedPrefsHelper.getBool(
        AppConstants.keyOnboardingDone,
      );
      if (!onboardingDone) {
        Navigator.pushReplacementNamed(context, AppConstants.routeOnboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
      }
    }
  }

  @override
  void dispose() {
    _flyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.moniflyVertical),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated bird/logo
              SlideTransition(
                position: _flyAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo/logo_monifly.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              // Loading dots
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => _AnimatedDot(delay: Duration(milliseconds: i * 200)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _a = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FadeTransition(
        opacity: _a,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

