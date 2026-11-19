import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/budget_provider.dart';
import 'providers/pin_lock_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  final profileProvider = ProfileProvider();
  final pinLockProvider = PinLockProvider();
  await themeProvider.loadTheme();
  await profileProvider.loadProfile();
  await pinLockProvider.load();

  runApp(
    ElistaApp(
      themeProvider: themeProvider,
      profileProvider: profileProvider,
      pinLockProvider: pinLockProvider,
    ),
  );
}

class ElistaApp extends StatelessWidget {
  const ElistaApp({
    required this.themeProvider,
    required this.profileProvider,
    required this.pinLockProvider,
    super.key,
  });

  final ThemeProvider themeProvider;
  final ProfileProvider profileProvider;
  final PinLockProvider pinLockProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<PinLockProvider>.value(value: pinLockProvider),
        ChangeNotifierProvider<BudgetProvider>(
          create: (_) => BudgetProvider()..loadBudgets(),
        ),
        ChangeNotifierProvider<WalletProvider>(
          create: (_) => WalletProvider()..loadTransactions(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'eLista',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
