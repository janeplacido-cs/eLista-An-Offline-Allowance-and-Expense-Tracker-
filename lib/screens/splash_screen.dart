import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'pin_lock_gate.dart';
import 'setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.6,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _openDashboard();
  }

  Future<void> _openDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final profile = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    if (!profile.isSetupComplete) {
      final wallet = context.read<WalletProvider>();
      await wallet.loadTransactions();
      if (!mounted) return;
      if (wallet.transactions.isNotEmpty) {
        await profile.skipSetup();
        if (!mounted) return;
      }
    }

    final destination = profile.isSetupComplete
        ? const PinLockGate(child: MainNavigationScreen())
        : const SetupScreen();
    await navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = Image.asset(
      'assets/images/logo.png',
      height: 210,
      fit: BoxFit.contain,
      semanticLabel: 'eLista — Track Your Wallet, Every Peso',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: isDark
                ? Container(
                    key: const ValueKey('splash-logo-light-surface'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.light.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: logo,
                  )
                : logo,
          ),
        ),
      ),
    );
  }
}
