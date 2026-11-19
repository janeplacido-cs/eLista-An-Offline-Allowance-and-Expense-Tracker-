import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../providers/budget_provider.dart';
import '../providers/pin_lock_provider.dart';
import '../providers/wallet_provider.dart';

class PinLockGate extends StatefulWidget {
  const PinLockGate({required this.child, this.clock, super.key});

  final Widget child;
  final DateTime Function()? clock;

  @override
  State<PinLockGate> createState() => _PinLockGateState();
}

class _PinLockGateState extends State<PinLockGate> with WidgetsBindingObserver {
  late bool _isLocked;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    _isLocked = context.read<PinLockProvider>().isEnabled;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _backgroundedAt ??= _now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null ||
        _now().difference(backgroundedAt) <= const Duration(seconds: 30) ||
        !context.read<PinLockProvider>().isEnabled ||
        _isLocked) {
      return;
    }
    setState(() => _isLocked = true);
  }

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  Future<void> _forgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erase app data?'),
        content: const Text(
          'This permanently deletes all allowance, transaction, and budget '
          'data and removes the PIN. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final pinProvider = context.read<PinLockProvider>();
    final walletProvider = context.read<WalletProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    try {
      await DbHelper.instance.clearAllData();
      await Future.wait([
        walletProvider.loadTransactions(),
        budgetProvider.loadBudgets(),
      ]);
      await pinProvider.clearPin();
      if (mounted) setState(() => _isLocked = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not erase app data: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinProvider = context.watch<PinLockProvider>();
    if (pinProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (pinProvider.loadError != null) {
      return _PinStorageErrorScreen(
        error: pinProvider.loadError!,
        onRetry: pinProvider.load,
        onForgotPin: _forgotPin,
      );
    }
    if (!_isLocked || !pinProvider.isEnabled) return widget.child;

    return PinLockScreen(
      onUnlocked: () {
        if (mounted) setState(() => _isLocked = false);
      },
      onForgotPin: _forgotPin,
    );
  }
}

class _PinStorageErrorScreen extends StatelessWidget {
  const _PinStorageErrorScreen({
    required this.error,
    required this.onRetry,
    required this.onForgotPin,
  });

  final Object error;
  final VoidCallback onRetry;
  final Future<void> Function() onForgotPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load PIN settings.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
                TextButton(
                  onPressed: onForgotPin,
                  child: const Text('Forgot PIN? Erase app data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({
    required this.onUnlocked,
    required this.onForgotPin,
    super.key,
  });

  final VoidCallback onUnlocked;
  final Future<void> Function() onForgotPin;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  final StringBuffer _enteredDigits = StringBuffer();
  Timer? _lockoutTimer;
  DateTime? _lockedUntil;
  String? _message;
  int _failedAttempts = 0;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_isVerifying || _lockedUntil != null || _enteredDigits.length >= 4) {
      return;
    }
    _enteredDigits.write(digit);
    setState(() => _message = null);
    if (_enteredDigits.length == 4) _verifyEnteredPin();
  }

  void _removeDigit() {
    if (_isVerifying || _lockedUntil != null || _enteredDigits.isEmpty) return;
    final digits = _enteredDigits.toString();
    _enteredDigits
      ..clear()
      ..write(digits.substring(0, digits.length - 1));
    setState(() => _message = null);
  }

  Future<void> _verifyEnteredPin() async {
    final pin = _enteredDigits.toString();
    setState(() => _isVerifying = true);
    try {
      final valid = await context.read<PinLockProvider>().verifyPin(pin);
      if (!mounted) return;
      if (valid) {
        widget.onUnlocked();
      } else {
        _registerFailure();
      }
    } catch (error) {
      if (!mounted) return;
      _enteredDigits.clear();
      setState(() => _message = 'Could not verify PIN: $error');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _registerFailure() {
    _enteredDigits.clear();
    _shakeController.forward(from: 0);
    _failedAttempts++;
    if (_failedAttempts < 5) {
      setState(() => _message = 'Incorrect PIN. Try again.');
      return;
    }

    _failedAttempts = 0;
    _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
    setState(() => _message = 'Too many attempts. Try again in 30 seconds.');
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final lockedUntil = _lockedUntil;
      if (lockedUntil == null || !DateTime.now().isBefore(lockedUntil)) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _lockedUntil = null;
          _message = null;
        });
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  int get _lockoutSeconds {
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) return 0;
    return math.max(0, lockedUntil.difference(DateTime.now()).inSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lockedOut = _lockedUntil != null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 40,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your PIN',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _shakeOffset,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(_shakeOffset.value, 0),
                            child: child,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List<Widget>.generate(
                              4,
                              (index) => Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < _enteredDigits.length
                                      ? colors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: colors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 22,
                          child: Text(
                            lockedOut
                                ? 'Try again in $_lockoutSeconds seconds.'
                                : _message ?? '',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _message == null
                                  ? colors.onSurfaceVariant
                                  : colors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        for (final row in const [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          ['', '0', 'delete'],
                        ]) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final key in row) _keyButton(key, colors),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: _isVerifying ? null : widget.onForgotPin,
                      child: const Text('Forgot PIN?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String key, ColorScheme colors) {
    if (key.isEmpty) return const SizedBox(width: 72, height: 58);
    if (key == 'delete') {
      return SizedBox(
        width: 72,
        height: 58,
        child: IconButton(
          tooltip: 'Delete last digit',
          onPressed: _lockedUntil == null ? _removeDigit : null,
          icon: const Icon(Icons.backspace_outlined),
        ),
      );
    }

    return SizedBox(
      width: 72,
      height: 58,
      child: TextButton(
        onPressed: _lockedUntil == null && !_isVerifying
            ? () => _addDigit(key)
            : null,
        style: TextButton.styleFrom(
          foregroundColor: colors.onSurface,
          shape: const CircleBorder(),
        ),
        child: Text(key, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
