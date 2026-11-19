import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AllowancePeriodCard extends StatelessWidget {
  const AllowancePeriodCard({
    required this.startDate,
    required this.endDate,
    required this.remainingBalance,
    required this.todayExpenses,
    required this.onAddAllowance,
    required this.onExtendPeriod,
    super.key,
  });

  final DateTime startDate;
  final DateTime endDate;
  final double remainingBalance;
  final double todayExpenses;
  final VoidCallback onAddAllowance;
  final VoidCallback onExtendPeriod;

  static final DateFormat _dateFormat = DateFormat('EEE, d MMM');
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
    final statusColors =
        theme.extension<AppStatusColors>() ??
        AppStatusColors.forColorScheme(colors, theme.brightness);
    final today = DateUtils.dateOnly(DateTime.now());
    final end = DateUtils.dateOnly(endDate);

    if (today.isAfter(end)) {
      return _endedCard(context, textStyles);
    }

    final daysLeft = end.difference(today).inDays + 1;
    final safeToSpend = remainingBalance > 0 && daysLeft > 0
        ? remainingBalance / daysLeft
        : 0.0;
    final isOverBudget = remainingBalance <= 0;
    final onTrack = !isOverBudget && todayExpenses <= safeToSpend;
    final statusColor = isOverBudget
        ? statusColors.error
        : onTrack
        ? statusColors.success
        : statusColors.warning;
    final statusLabel = isOverBudget
        ? 'Over budget'
        : onTrack
        ? 'On track'
        : 'Slow down';
    final start = DateUtils.dateOnly(startDate);
    final duration = end.difference(start).inDays;
    final elapsed = today.difference(start).inDays;
    final progress = duration <= 0
        ? (today.isBefore(start) ? 0.0 : 1.0)
        : (elapsed / duration).clamp(0.0, 1.0).toDouble();
    final daysLabel = daysLeft == 1 ? 'Last day' : '$daysLeft days left';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Allowance period',
                    style: textStyles.sectionHeader,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ends ${_dateFormat.format(end)}',
                    style: textStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              daysLabel,
              style: textStyles.itemTitle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: colors.primary,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text.rich(
                  TextSpan(
                    style: textStyles.caption,
                    children: [
                      const TextSpan(text: 'Safe to spend today: '),
                      TextSpan(
                        text: _currency.format(safeToSpend),
                        style: textStyles.itemTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: textStyles.chipLabel.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _endedCard(BuildContext context, AppTextStyles textStyles) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allowance period ended',
              style: textStyles.sectionHeader.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onAddAllowance,
                  child: const Text('Add new allowance'),
                ),
                OutlinedButton(
                  onPressed: onExtendPeriod,
                  child: const Text('Extend period'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
