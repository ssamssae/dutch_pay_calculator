import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'services/account_service.dart';
import 'services/ads_service.dart';
import 'services/iap_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.init();
  await IapService.init();
  await AccountService.init();
  runApp(const DutchPayApp());
}

class DutchPayApp extends StatelessWidget {
  const DutchPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '더치페이 계산기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}

// --- Splash Screen ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 네이티브 런치 스크린(검정)에서 이어지는 단일 스플래시 — 1.5초 노출 후 전환.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const MainShell(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (context, animation, a2, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkColors.bgDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: DarkColors.accent.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: DarkColors.surface,
                    child: const Icon(
                      Icons.calculate_rounded,
                      size: 56,
                      color: DarkColors.accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '더치페이 계산기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DarkColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
