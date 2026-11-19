import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class RemainingBalanceCard extends StatelessWidget {
  const RemainingBalanceCard({required this.balance, super.key});

  final double balance;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? colors.primaryContainer : colors.secondary;
    final foreground = isDark ? colors.onPrimaryContainer : colors.onPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [background, colors.primary]
              : [colors.primary, background],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Balance',
                  style: textStyles.sectionHeader.copyWith(color: foreground),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'WALLET ACTIVE',
                  style: textStyles.chipLabel.copyWith(
                    color: foreground,
                    fontSize: 9,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            _currency.format(balance),
            style: textStyles.largeAmount.copyWith(
              color: foreground,
              fontSize: 34,
            ),
          ),
        ],
      ),
    );
  }
}
