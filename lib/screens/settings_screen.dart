import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/pin_lock_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/allowance_end_date_picker.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: AppLayout.screenContentPadding,
                children: [
                  Text(
                    'Account',
                    style: textStyles.sectionHeader.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Consumer<ProfileProvider>(
                      builder: (context, profile, _) => ListTile(
                        key: const ValueKey('profile-name-tile'),
                        leading: Icon(
                          Icons.person_outline_rounded,
                          color: colors.primary,
                        ),
                        title: const Text('Name'),
                        subtitle: Text(
                          profile.name.isEmpty ? 'Not set' : profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _editName(context, profile.name),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Appearance',
                    style: textStyles.sectionHeader.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => SwitchListTile(
                        key: const ValueKey('dark-mode-switch'),
                        secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_outlined,
                          color: colors.primary,
                        ),
                        title: const Text('Dark mode'),
                        subtitle: const Text('Use a darker color theme'),
                        value: themeProvider.isDarkMode,
                        onChanged: (enabled) => _setDarkMode(context, enabled),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Security',
                    style: textStyles.sectionHeader.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Consumer<PinLockProvider>(
                      builder: (context, pinLock, _) => Column(
                        children: [
                          SwitchListTile(
                            key: const ValueKey('pin-lock-switch'),
                            secondary: Icon(
                              Icons.lock_outline_rounded,
                              color: colors.primary,
                            ),
                            title: const Text('Enable PIN lock'),
                            subtitle: Text(
                              pinLock.isEnabled
                                  ? 'Require your PIN to unlock eLista'
                                  : 'Protect this app with a 4-digit PIN',
                            ),
                            value: pinLock.isEnabled,
                            onChanged: (enabled) => enabled
                                ? _enablePin(context)
                                : _disablePin(context),
                          ),
                          if (pinLock.isEnabled) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            ListTile(
                              leading: Icon(
                                Icons.password_rounded,
                                color: colors.primary,
                              ),
                              title: const Text('Change PIN'),
                              onTap: () => _changePin(context),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.lock_open_rounded,
                                color: colors.primary,
                              ),
                              title: const Text('Disable PIN'),
                              onTap: () => _disablePin(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Preferences',
                    style: textStyles.sectionHeader.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.currency_exchange_rounded,
                            color: colors.primary,
                          ),
                          title: const Text('Currency'),
                          trailing: Text(
                            'PHP (₱)',
                            style: textStyles.itemSubtitle,
                          ),
                        ),
                        Divider(height: 1, color: colors.outlineVariant),
                        Consumer<WalletProvider>(
                          builder: (context, wallet, _) {
                            final endDate = wallet.allowancePeriodEndDate;
                            return ListTile(
                              key: const ValueKey('allowance-end-date-setting'),
                              leading: Icon(
                                Icons.event_outlined,
                                color: colors.primary,
                              ),
                              title: const Text('Allowance end date'),
                              subtitle: Text(
                                endDate == null
                                    ? 'Not set'
                                    : DateFormat(
                                        'EEE, d MMM yyyy',
                                      ).format(endDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: endDate == null
                                  ? Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.onSurfaceVariant,
                                    )
                                  : IconButton(
                                      tooltip: 'Clear allowance end date',
                                      onPressed: () => _clearAllowanceEndDate(
                                        context,
                                        wallet,
                                      ),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              onTap: () =>
                                  _changeAllowanceEndDate(context, wallet),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About',
                    style: textStyles.sectionHeader.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: colors.primary,
                          ),
                          title: const Text('eLista'),
                          subtitle: const Text(
                            'Offline allowance and expense tracker',
                          ),
                        ),
                        Divider(height: 1, color: colors.outlineVariant),
                        ListTile(
                          leading: Icon(
                            Icons.wifi_off_rounded,
                            color: colors.primary,
                          ),
                          title: const Text('Your data stays on this device'),
                          subtitle: const Text(
                            'No account or internet connection is needed.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, String currentName) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(name: currentName),
    );
    if (name == null || !context.mounted) return;

    try {
      await context.read<ProfileProvider>().updateName(name);
      if (!context.mounted) return;
      _showMessage(context, 'Name updated.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not save name: $error');
    }
  }

  Future<void> _changeAllowanceEndDate(
    BuildContext context,
    WalletProvider wallet,
  ) async {
    final selected = await showAllowanceEndDatePicker(
      context,
      initialDate: wallet.allowancePeriodEndDate,
    );
    if (selected == null || !context.mounted) return;
    try {
      await wallet.setAllowancePeriodEndDate(selected);
      if (!context.mounted) return;
      _showMessage(context, 'Allowance end date updated.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not update allowance end date: $error');
    }
  }

  Future<void> _clearAllowanceEndDate(
    BuildContext context,
    WalletProvider wallet,
  ) async {
    try {
      await wallet.setAllowancePeriodEndDate(null);
      if (!context.mounted) return;
      _showMessage(context, 'Allowance end date cleared.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not clear allowance end date: $error');
    }
  }

  Future<void> _enablePin(BuildContext context) async {
    final result = await _showPinDialog(context, mode: _PinDialogMode.enable);
    if (result == null || !context.mounted) return;
    try {
      await context.read<PinLockProvider>().enablePin(result.newPin!);
      if (!context.mounted) return;
      _showMessage(context, 'PIN lock enabled.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not enable PIN lock: $error');
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final result = await _showPinDialog(context, mode: _PinDialogMode.change);
    if (result == null || !context.mounted) return;
    try {
      final changed = await context.read<PinLockProvider>().changePin(
        currentPin: result.currentPin!,
        newPin: result.newPin!,
      );
      if (!context.mounted) return;
      _showMessage(
        context,
        changed ? 'PIN changed.' : 'The current PIN is incorrect.',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not change PIN: $error');
    }
  }

  Future<void> _disablePin(BuildContext context) async {
    final result = await _showPinDialog(context, mode: _PinDialogMode.disable);
    if (result == null || !context.mounted) return;
    try {
      final disabled = await context.read<PinLockProvider>().disablePin(
        result.currentPin!,
      );
      if (!context.mounted) return;
      _showMessage(
        context,
        disabled ? 'PIN lock disabled.' : 'The current PIN is incorrect.',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not disable PIN lock: $error');
    }
  }

  Future<_PinDialogResult?> _showPinDialog(
    BuildContext context, {
    required _PinDialogMode mode,
  }) {
    return showDialog<_PinDialogResult>(
      context: context,
      builder: (_) => _PinManagementDialog(mode: mode),
    );
  }

  Future<void> _setDarkMode(BuildContext context, bool enabled) async {
    try {
      await context.read<ThemeProvider>().setDarkMode(enabled);
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not save theme setting: $error');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.name});

  final String name;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.isEmpty) return 'Enter a name.';
            if (name.runes.length > 30) {
              return 'Name must be 30 characters or less.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

enum _PinDialogMode { enable, change, disable }

class _PinDialogResult {
  const _PinDialogResult({this.currentPin, this.newPin});

  final String? currentPin;
  final String? newPin;
}

class _PinManagementDialog extends StatefulWidget {
  const _PinManagementDialog({required this.mode});

  final _PinDialogMode mode;

  @override
  State<_PinManagementDialog> createState() => _PinManagementDialogState();
}

class _PinManagementDialogState extends State<_PinManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool get _hasCurrentPin => widget.mode != _PinDialogMode.enable;
  bool get _hasNewPin => widget.mode != _PinDialogMode.disable;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PinDialogResult(
        currentPin: _hasCurrentPin ? _currentController.text : null,
        newPin: _hasNewPin ? _newController.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      _PinDialogMode.enable => 'Set a 4-digit PIN',
      _PinDialogMode.change => 'Change PIN',
      _PinDialogMode.disable => 'Disable PIN',
    };

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasCurrentPin) _pinField(_currentController, 'Current PIN'),
              if (_hasNewPin) ...[
                if (_hasCurrentPin) const SizedBox(height: 12),
                _pinField(_newController, 'New PIN'),
                const SizedBox(height: 12),
                _pinField(
                  _confirmController,
                  'Confirm new PIN',
                  validator: (value) {
                    if (value != _newController.text) {
                      return 'PINs do not match.';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }

  Widget _pinField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => RegExp(r'^\d{4}$').hasMatch(value ?? '')
              ? null
              : 'Enter a 4-digit PIN.',
    );
  }
}
