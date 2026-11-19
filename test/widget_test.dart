import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elista/providers/theme_provider.dart';
import 'package:elista/providers/pin_lock_provider.dart';
import 'package:elista/providers/profile_provider.dart';
import 'package:elista/providers/wallet_provider.dart';
import 'package:elista/providers/budget_provider.dart';
import 'package:elista/screens/settings_screen.dart';
import 'package:elista/screens/setup_screen.dart';
import 'package:elista/screens/splash_screen.dart';
import 'package:elista/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  test('dark theme uses the requested accessible palette', () {
    final theme = AppTheme.dark;
    expect(theme.colorScheme.primary, const Color(0xFF4DA3FF));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0E1621));
    expect(theme.colorScheme.surface, const Color(0xFF182433));
    expect(theme.colorScheme.onSurface, const Color(0xFFE6EEF7));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF9FB3C8));
    expect(theme.colorScheme.error, const Color(0xFFFF6B6B));
  });

  test('theme preference persists locally', () async {
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();

    await themeProvider.loadTheme();
    expect(themeProvider.isDarkMode, isFalse);

    await themeProvider.setDarkMode(true);
    final restoredProvider = ThemeProvider();
    await restoredProvider.loadTheme();

    expect(restoredProvider.isDarkMode, isTrue);
  });

  testWidgets('settings toggle applies and saves dark mode', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();
    final profileProvider = ProfileProvider();
    final pinLockProvider = PinLockProvider();
    await themeProvider.loadTheme();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<PinLockProvider>.value(value: pinLockProvider),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(),
          ),
          ChangeNotifierProvider<BudgetProvider>(
            create: (_) => BudgetProvider(),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.themeMode,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.byKey(const ValueKey('dark-mode-switch')));
    await tester.pumpAndSettle();

    expect(themeProvider.isDarkMode, isTrue);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      (await SharedPreferences.getInstance()).getBool('dark_mode_enabled'),
      isTrue,
    );
  });

  testWidgets('settings name edit persists and updates the profile provider', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'profile_name': 'Alex'});
    final profileProvider = ProfileProvider();
    await profileProvider.loadProfile();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
          ChangeNotifierProvider<PinLockProvider>.value(
            value: PinLockProvider(),
          ),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
      ),
    );

    expect(find.text('Alex'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-name-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Alexandra');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(profileProvider.name, 'Alexandra');
    expect(find.text('Alexandra'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('profile_name'),
      'Alexandra',
    );
  });

  testWidgets('splash screen displays the eLista brand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );
    await tester.pump(const Duration(milliseconds: 750));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/images/logo.png');
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppTheme.light.scaffoldBackgroundColor,
    );
    expect(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(ScaleTransition),
      ),
      findsWidgets,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1750));
  });

  testWidgets('dark splash keeps the logo visible on a light surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppTheme.dark.scaffoldBackgroundColor,
    );
    expect(
      find.byKey(const ValueKey('splash-logo-light-surface')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('first-run setup shows profile and PIN fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SetupScreen()),
    );

    expect(find.text('Set up eLista'), findsOneWidget);
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('CREATE PIN'), findsOneWidget);
    expect(find.text('CONFIRM PIN'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip PIN for now'), findsOneWidget);
    expect(find.text('Allowance cycle'), findsNothing);
    expect(find.text('Allowance amount'), findsNothing);
  });

  testWidgets('dark setup uses dark surfaces and a light logo backing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const SetupScreen(),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppTheme.dark.scaffoldBackgroundColor,
    );
    expect(
      find.byKey(const ValueKey('setup-logo-light-surface')),
      findsOneWidget,
    );
  });

  testWidgets('skip PIN saves the name and disables the PIN', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final profileProvider = ProfileProvider();
    final pinLockProvider = PinLockProvider(storage: _MemoryPinStorage());
    await pinLockProvider.enablePin('1234');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<PinLockProvider>.value(value: pinLockProvider),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(),
          ),
          ChangeNotifierProvider<BudgetProvider>(
            create: (_) => BudgetProvider(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SetupScreen()),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('setup-name')), 'Mika');
    await tester.ensureVisible(find.byKey(const ValueKey('setup-skip-pin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('setup-skip-pin')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(profileProvider.name, 'Mika');
    expect(profileProvider.isSetupComplete, isTrue);
    expect(pinLockProvider.isEnabled, isFalse);
  });

  testWidgets('setup validates PIN length and confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>(
            create: (_) => ProfileProvider(),
          ),
          ChangeNotifierProvider<PinLockProvider>(
            create: (_) => PinLockProvider(storage: _MemoryPinStorage()),
          ),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SetupScreen()),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('setup-name')), 'Mika');
    await tester.enterText(find.byKey(const ValueKey('setup-pin')), '123');
    await tester.pump();
    expect(find.text('PIN must contain 4 to 6 digits.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('setup-pin')), '1234');
    await tester.enterText(
      find.byKey(const ValueKey('setup-confirm-pin')),
      '1235',
    );
    await tester.pump();
    expect(find.text('PINs do not match.'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('setup-get-started')),
    );
    expect(button.onPressed, isNull);
  });
}

class _MemoryPinStorage implements PinRecordStorage {
  String? record;

  @override
  Future<String?> readRecord() async => record;

  @override
  Future<void> writeRecord(String value) async {
    record = value;
  }

  @override
  Future<void> clearRecord() async {
    record = null;
  }
}
