import 'package:flutter/material.dart';

class AppTheme {
  static const Color splashBackground = Color(0xFF0077B8);
  static const Color _blue = splashBackground;
  static const Color _navy = Color(0xFF03035D);
  static const Color _cyan = Color(0xFF00BBDE);
  static const Color _lightCanvas = Color(0xFFF4F9FB);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightField = Color(0xFFECF7FD);
  static const Color _darkPrimary = Color(0xFF4DA3FF);
  static const Color _darkBackground = Color(0xFF0E1621);
  static const Color _darkSurface = Color(0xFF182433);
  static const Color _darkText = Color(0xFFE6EEF7);
  static const Color _darkMuted = Color(0xFF9FB3C8);
  static const Color _expense = Color(0xFFD84358);
  static const Color _expenseDark = Color(0xFFFF6B6B);
  static const Color _income = Color(0xFF21875A);
  static const Color _incomeDark = Color(0xFF70D6A4);
  static const Color _transport = Color(0xFF2878C8);
  static const Color _transportDark = Color(0xFF6AB6FF);
  static const Color _school = Color(0xFFB36B12);
  static const Color _schoolDark = Color(0xFFFFD36E);
  static const Color _neutral = Color(0xFF687583);
  static const Color _neutralDark = _darkMuted;
  static const String fontFamily = 'Roboto';

  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    seedColor: _blue,
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    seedColor: _darkPrimary,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      primary: isDark ? _darkPrimary : _blue,
      onPrimary: isDark ? _darkBackground : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF203954)
          : const Color(0xFFCAF0F8),
      onPrimaryContainer: isDark ? _darkText : _navy,
      secondary: isDark ? _darkMuted : _navy,
      onSecondary: isDark ? _darkBackground : Colors.white,
      tertiary: isDark ? const Color(0xFF5CCDE3) : _cyan,
      onTertiary: isDark ? _darkBackground : _navy,
      error: isDark ? _expenseDark : generated.error,
      onError: isDark ? _darkBackground : generated.onError,
      errorContainer: isDark
          ? const Color(0xFF5C272C)
          : generated.errorContainer,
      onErrorContainer: isDark
          ? const Color(0xFFFFDADB)
          : generated.onErrorContainer,
      surface: isDark ? _darkSurface : _lightCanvas,
      onSurface: isDark ? _darkText : _navy,
      surfaceContainerLowest: isDark ? _darkBackground : _lightCard,
      surfaceContainerLow: isDark ? _darkSurface : _lightCard,
      surfaceContainer: isDark ? const Color(0xFF1D2A39) : _lightCard,
      surfaceContainerHigh: isDark ? const Color(0xFF233346) : _lightField,
      surfaceContainerHighest: isDark ? const Color(0xFF29394B) : _lightField,
      onSurfaceVariant: isDark ? _darkMuted : const Color(0xFF5F7483),
      outlineVariant: isDark
          ? const Color(0xFF405469)
          : const Color(0xFFD8E8EE),
      inverseSurface: isDark ? _darkText : _navy,
      onInverseSurface: isDark ? _darkBackground : Colors.white,
      inversePrimary: isDark ? _blue : _cyan,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      extensions: [
        AppTextStyles.fromColorScheme(scheme),
        AppTransactionColors(
          expense: isDark ? _expenseDark : _expense,
          income: isDark ? _incomeDark : _income,
          transport: isDark ? _transportDark : _transport,
          school: isDark ? _schoolDark : _school,
          neutral: isDark ? _neutralDark : _neutral,
        ),
        AppStatusColors.forColorScheme(scheme, brightness),
        AppBudgetColors.forBrightness(brightness),
      ],
      scaffoldBackgroundColor: isDark ? _darkBackground : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _darkBackground : scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _darkSurface : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF263A50)
            : const Color(0xFFCAF0F8),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: isDark
                ? (selected ? _darkPrimary : _darkMuted)
                : (selected ? _blue : const Color(0xFF7485AD)),
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTextStyles.fromColorScheme(scheme).itemTitle,
        subtitleTextStyle: AppTextStyles.fromColorScheme(scheme).itemSubtitle,
      ),
    );
  }
}

class AppLayout {
  const AppLayout._();

  static const double screenHorizontalPadding = 20;
  static const double headerRightPadding = 16;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 8;
  static const double headerRowHeight = 52;
  static const double headerTrailingSpacing = 8;
  static const double headerTrailingSize = 48;
  static const double headerContentGap = 4;
  static const double screenBottomPadding = 28;

  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(
    screenHorizontalPadding,
    headerTopPadding,
    headerRightPadding,
    headerBottomPadding,
  );
  static const EdgeInsets screenContentPadding = EdgeInsets.fromLTRB(
    screenHorizontalPadding,
    headerContentGap,
    screenHorizontalPadding,
    screenBottomPadding,
  );
  static const EdgeInsets screenHorizontalInsets = EdgeInsets.symmetric(
    horizontal: screenHorizontalPadding,
  );
}

@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.screenTitle,
    required this.sectionHeader,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.amount,
    required this.chipLabel,
    required this.buttonLabel,
    required this.caption,
    required this.largeAmount,
    required this.fieldLabel,
    required this.pageSubtitle,
  });

  factory AppTextStyles.fromColorScheme(ColorScheme colors) {
    return AppTextStyles(
      screenTitle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: colors.onSurface,
      ),
      sectionHeader: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      itemTitle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      itemSubtitle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colors.onSurfaceVariant,
      ),
      amount: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      chipLabel: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: colors.primary,
      ),
      buttonLabel: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: colors.onPrimary,
      ),
      caption: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colors.onSurfaceVariant,
      ),
      largeAmount: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: colors.onSurface,
      ),
      fieldLabel: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: colors.onSurfaceVariant,
      ),
      pageSubtitle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  final TextStyle screenTitle;
  final TextStyle sectionHeader;
  final TextStyle itemTitle;
  final TextStyle itemSubtitle;
  final TextStyle amount;
  final TextStyle chipLabel;
  final TextStyle buttonLabel;
  final TextStyle caption;
  final TextStyle largeAmount;
  final TextStyle fieldLabel;
  final TextStyle pageSubtitle;

  static AppTextStyles of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTextStyles>() ??
        AppTextStyles.fromColorScheme(theme.colorScheme);
  }

  @override
  AppTextStyles copyWith({
    TextStyle? screenTitle,
    TextStyle? sectionHeader,
    TextStyle? itemTitle,
    TextStyle? itemSubtitle,
    TextStyle? amount,
    TextStyle? chipLabel,
    TextStyle? buttonLabel,
    TextStyle? caption,
    TextStyle? largeAmount,
    TextStyle? fieldLabel,
    TextStyle? pageSubtitle,
  }) {
    return AppTextStyles(
      screenTitle: screenTitle ?? this.screenTitle,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      itemTitle: itemTitle ?? this.itemTitle,
      itemSubtitle: itemSubtitle ?? this.itemSubtitle,
      amount: amount ?? this.amount,
      chipLabel: chipLabel ?? this.chipLabel,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      caption: caption ?? this.caption,
      largeAmount: largeAmount ?? this.largeAmount,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      pageSubtitle: pageSubtitle ?? this.pageSubtitle,
    );
  }

  @override
  AppTextStyles lerp(covariant AppTextStyles? other, double t) {
    if (other == null) return this;
    return AppTextStyles(
      screenTitle: TextStyle.lerp(screenTitle, other.screenTitle, t)!,
      sectionHeader: TextStyle.lerp(sectionHeader, other.sectionHeader, t)!,
      itemTitle: TextStyle.lerp(itemTitle, other.itemTitle, t)!,
      itemSubtitle: TextStyle.lerp(itemSubtitle, other.itemSubtitle, t)!,
      amount: TextStyle.lerp(amount, other.amount, t)!,
      chipLabel: TextStyle.lerp(chipLabel, other.chipLabel, t)!,
      buttonLabel: TextStyle.lerp(buttonLabel, other.buttonLabel, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      largeAmount: TextStyle.lerp(largeAmount, other.largeAmount, t)!,
      fieldLabel: TextStyle.lerp(fieldLabel, other.fieldLabel, t)!,
      pageSubtitle: TextStyle.lerp(pageSubtitle, other.pageSubtitle, t)!,
    );
  }
}

@immutable
class AppTransactionColors extends ThemeExtension<AppTransactionColors> {
  const AppTransactionColors({
    required this.expense,
    required this.income,
    required this.transport,
    required this.school,
    required this.neutral,
  });

  final Color expense;
  final Color income;
  final Color transport;
  final Color school;
  final Color neutral;

  @override
  AppTransactionColors copyWith({
    Color? expense,
    Color? income,
    Color? transport,
    Color? school,
    Color? neutral,
  }) {
    return AppTransactionColors(
      expense: expense ?? this.expense,
      income: income ?? this.income,
      transport: transport ?? this.transport,
      school: school ?? this.school,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AppTransactionColors lerp(
    covariant ThemeExtension<AppTransactionColors>? other,
    double t,
  ) {
    if (other is! AppTransactionColors) return this;
    return AppTransactionColors(
      expense: Color.lerp(expense, other.expense, t)!,
      income: Color.lerp(income, other.income, t)!,
      transport: Color.lerp(transport, other.transport, t)!,
      school: Color.lerp(school, other.school, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.error,
  });

  factory AppStatusColors.forColorScheme(
    ColorScheme colors,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    return AppStatusColors(
      success: isDark ? const Color(0xFF70D6A4) : const Color(0xFF2E7D4F),
      warning: isDark ? const Color(0xFFFFC857) : const Color(0xFFB36B12),
      error: colors.error,
    );
  }

  final Color success;
  final Color warning;
  final Color error;

  @override
  AppStatusColors copyWith({Color? success, Color? warning, Color? error}) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppStatusColors lerp(
    covariant ThemeExtension<AppStatusColors>? other,
    double t,
  ) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

@immutable
class AppBudgetColors extends ThemeExtension<AppBudgetColors> {
  const AppBudgetColors({
    required this.navy,
    required this.cyan,
    required this.summaryBackground,
    required this.expense,
    required this.remaining,
    required this.muted,
    required this.track,
    required this.outline,
    required this.shadow,
    required this.categoryColors,
  });

  static const AppBudgetColors light = AppBudgetColors(
    navy: Color(0xFF0A0A5C),
    cyan: Color(0xFF00B4D8),
    summaryBackground: Color(0xFFCDF1F8),
    expense: Color(0xFFD62839),
    remaining: Color(0xFF2E7D4F),
    muted: Color(0xFF777AA8),
    track: Color(0xFFBDEEF5),
    outline: Color(0xFFD8E8EE),
    shadow: Color(0x180A0A5C),
    categoryColors: [
      Color(0xFF0077B6),
      Color(0xFF00B4D8),
      Color(0xFF90E0EF),
      Color(0xFF6C63C7),
      Color(0xFF4F9D69),
      Color(0xFFE59A37),
    ],
  );

  static const AppBudgetColors dark = AppBudgetColors(
    navy: Color(0xFFE6EEF7),
    cyan: Color(0xFF4DA3FF),
    summaryBackground: Color(0xFF182433),
    expense: Color(0xFFFF6B6B),
    remaining: Color(0xFF70D6A4),
    muted: Color(0xFF9FB3C8),
    track: Color(0xFF29394B),
    outline: Color(0xFF405469),
    shadow: Color(0x44000000),
    categoryColors: [
      Color(0xFF65B9F5),
      Color(0xFF4DA3FF),
      Color(0xFFBDECF2),
      Color(0xFFAAA1FF),
      Color(0xFF70D6A4),
      Color(0xFFFFD36E),
    ],
  );

  final Color navy;
  final Color cyan;
  final Color summaryBackground;
  final Color expense;
  final Color remaining;
  final Color muted;
  final Color track;
  final Color outline;
  final Color shadow;
  final List<Color> categoryColors;

  factory AppBudgetColors.forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  Color categoryColor(String category, int index) {
    if (category == 'Food') return categoryColors[0];
    if (category == 'Transport') return categoryColors[1];
    if (category == 'School') return categoryColors[2];
    return categoryColors[3 + (index % (categoryColors.length - 3))];
  }

  @override
  AppBudgetColors copyWith({
    Color? navy,
    Color? cyan,
    Color? summaryBackground,
    Color? expense,
    Color? remaining,
    Color? muted,
    Color? track,
    Color? outline,
    Color? shadow,
    List<Color>? categoryColors,
  }) {
    return AppBudgetColors(
      navy: navy ?? this.navy,
      cyan: cyan ?? this.cyan,
      summaryBackground: summaryBackground ?? this.summaryBackground,
      expense: expense ?? this.expense,
      remaining: remaining ?? this.remaining,
      muted: muted ?? this.muted,
      track: track ?? this.track,
      outline: outline ?? this.outline,
      shadow: shadow ?? this.shadow,
      categoryColors: categoryColors ?? this.categoryColors,
    );
  }

  @override
  AppBudgetColors lerp(covariant AppBudgetColors? other, double t) {
    if (other == null) return this;
    return AppBudgetColors(
      navy: Color.lerp(navy, other.navy, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      summaryBackground: Color.lerp(
        summaryBackground,
        other.summaryBackground,
        t,
      )!,
      expense: Color.lerp(expense, other.expense, t)!,
      remaining: Color.lerp(remaining, other.remaining, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      track: Color.lerp(track, other.track, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      categoryColors: [
        for (var index = 0; index < categoryColors.length; index++)
          Color.lerp(categoryColors[index], other.categoryColors[index], t)!,
      ],
    );
  }
}
