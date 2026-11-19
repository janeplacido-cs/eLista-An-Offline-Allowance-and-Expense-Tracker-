import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/pin_lock_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _validateNameOnSkip = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  bool get _isNameValid {
    final name = _nameController.text.trim();
    return name.isNotEmpty && name.runes.length <= 30;
  }

  bool get _isValid {
    return _isNameValid &&
        RegExp(r'^\d{4,6}$').hasMatch(_pinController.text) &&
        _confirmPinController.text == _pinController.text;
  }

  Future<void> _getStarted() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = context.read<ProfileProvider>();
    final pinLock = context.read<PinLockProvider>();
    final name = _nameController.text.trim();
    setState(() => _isSaving = true);
    try {
      await profile.updateName(name);
      await pinLock.enablePin(_pinController.text);
      await profile.completeSetup(
        name: name,
        allowanceCycle: profile.allowanceCycle,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not finish setup: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _skipPin() async {
    if (!_isNameValid) {
      setState(() => _validateNameOnSkip = true);
      return;
    }

    final profile = context.read<ProfileProvider>();
    final pinLock = context.read<PinLockProvider>();
    setState(() => _isSaving = true);
    try {
      await profile.updateName(_nameController.text.trim());
      await pinLock.clearPin();
      await profile.skipSetup();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not continue: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
    final shapeOpacity = theme.brightness == Brightness.dark ? 0.045 : 0.09;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topHeight = math.min(constraints.maxHeight * 0.4, 320.0);
            final logoHeight = topHeight * 0.78;
            final imageHeight = theme.brightness == Brightness.dark
                ? math.max(0.0, logoHeight - 20)
                : logoHeight;
            final panelTop = math.max(0.0, topHeight - 28);
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final logoImage = Image.asset(
              'assets/images/logo.png',
              height: imageHeight,
              fit: BoxFit.contain,
              semanticLabel: 'eLista — Track Your Wallet, Every Peso',
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 28,
                        left: -48,
                        child: Transform.rotate(
                          angle: -0.22,
                          child: Container(
                            width: 190,
                            height: 54,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: shapeOpacity,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        right: -54,
                        child: Transform.rotate(
                          angle: math.pi / 5,
                          child: Container(
                            width: 190,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colors.tertiary.withValues(
                                alpha: shapeOpacity,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -66,
                        bottom: -82,
                        child: Container(
                          width: 176,
                          height: 176,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary.withValues(
                              alpha: shapeOpacity,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: theme.brightness == Brightness.dark
                            ? Container(
                                key: const ValueKey('setup-logo-light-surface'),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme
                                      .light
                                      .colorScheme
                                      .surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: logoImage,
                              )
                            : logoImage,
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  top: panelTop,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        28,
                        24,
                        24 + keyboardInset,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Set up eLista',
                              style: textStyles.screenTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your name and set a PIN to protect your data.',
                              style: textStyles.pageSubtitle.copyWith(
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _fieldLabel('NAME', textStyles, colors),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: const ValueKey('setup-name'),
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 30,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              autovalidateMode: _validateNameOnSkip
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.onUserInteraction,
                              style: textStyles.itemTitle.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _fieldDecoration(
                                hint: 'Juan',
                                colors: colors,
                                textStyles: textStyles,
                              ).copyWith(counterText: ''),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) return 'Enter your name.';
                                if (name.runes.length > 30) {
                                  return 'Name must be 30 characters or fewer.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel('CREATE PIN', textStyles, colors),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: const ValueKey('setup-pin'),
                              controller: _pinController,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              style: textStyles.itemTitle.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration:
                                  _fieldDecoration(
                                    hint: '4 to 6 digits',
                                    colors: colors,
                                    textStyles: textStyles,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePin
                                          ? 'Show PIN'
                                          : 'Hide PIN',
                                      onPressed: () => setState(
                                        () => _obscurePin = !_obscurePin,
                                      ),
                                      icon: Icon(
                                        _obscurePin
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (!RegExp(
                                  r'^\d{4,6}$',
                                ).hasMatch(value ?? '')) {
                                  return 'PIN must contain 4 to 6 digits.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel('CONFIRM PIN', textStyles, colors),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: const ValueKey('setup-confirm-pin'),
                              controller: _confirmPinController,
                              obscureText: _obscureConfirmPin,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              style: textStyles.itemTitle.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration:
                                  _fieldDecoration(
                                    hint: 'Re-enter your PIN',
                                    colors: colors,
                                    textStyles: textStyles,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _obscureConfirmPin
                                          ? 'Show PIN'
                                          : 'Hide PIN',
                                      onPressed: () => setState(
                                        () => _obscureConfirmPin =
                                            !_obscureConfirmPin,
                                      ),
                                      icon: Icon(
                                        _obscureConfirmPin
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value != _pinController.text) {
                                  return 'PINs do not match.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                key: const ValueKey('setup-get-started'),
                                onPressed: _isSaving || !_isValid
                                    ? null
                                    : _getStarted,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor:
                                      AppTheme.light.colorScheme.onPrimary,
                                  disabledBackgroundColor: colors.onSurface
                                      .withValues(alpha: 0.12),
                                  disabledForegroundColor:
                                      colors.onSurfaceVariant,
                                  shape: const StadiumBorder(),
                                  textStyle: textStyles.buttonLabel.copyWith(
                                    color: AppTheme.light.colorScheme.onPrimary,
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Get Started'),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                key: const ValueKey('setup-skip-pin'),
                                onPressed: _isSaving ? null : _skipPin,
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.primary,
                                  textStyle: textStyles.buttonLabel.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                                child: const Text('Skip PIN for now'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.wifi_off_rounded,
                                      size: 15,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Offline first · Your data stays on this phone',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textStyles.caption.copyWith(
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fieldLabel(
    String label,
    AppTextStyles textStyles,
    ColorScheme colors,
  ) {
    return Text(
      label,
      style: textStyles.fieldLabel.copyWith(color: colors.onSurfaceVariant),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required ColorScheme colors,
    required AppTextStyles textStyles,
  }) {
    final radius = BorderRadius.circular(12);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colors.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colors.primary, width: 1.2),
      ),
      errorStyle: textStyles.caption.copyWith(color: colors.error),
    );
  }
}
