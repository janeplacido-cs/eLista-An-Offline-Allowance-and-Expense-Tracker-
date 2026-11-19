import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weekly_spending_summary.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/weekly_spending_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static final DateFormat _dateFormat = DateFormat('MMM d');
  static final DateFormat _dayFormat = DateFormat('EEEE');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.isLoading && wallet.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wallet.loadError != null && wallet.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: colors.error,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load spending statistics.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: wallet.loadTransactions,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = WeeklySpendingSummary.fromTransactions(
            wallet.transactions,
          );
          final highestDate = summary.highestSpendingDate;
          final highestAmount = summary.highestDailySpending;

          return RefreshIndicator(
            onRefresh: wallet.loadTransactions,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text('This week', style: textStyles.screenTitle),
                const SizedBox(height: 4),
                Text(
                  '${_dateFormat.format(summary.weekStart)} – ${_dateFormat.format(summary.weekEnd)}',
                  style: textStyles.pageSubtitle,
                ),
                const SizedBox(height: 18),
                _WeekHighlightCard(
                  day: highestDate == null
                      ? null
                      : _dayFormat.format(highestDate),
                  amount: highestAmount,
                  total: summary.totalSpending,
                ),
                const SizedBox(height: 16),
                WeeklySpendingChart(summary: summary),
                if (wallet.loadError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Could not refresh transactions. Pull down to try again.',
                    style: textStyles.caption.copyWith(color: colors.error),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeekHighlightCard extends StatelessWidget {
  const _WeekHighlightCard({
    required this.day,
    required this.amount,
    required this.total,
  });

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final String? day;
  final double? amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.surface,
              foregroundColor: colors.primary,
              child: const Icon(Icons.trending_up_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day == null
                        ? 'No spending this week'
                        : 'Highest spending day',
                    style: textStyles.itemTitle.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    day == null
                        ? 'Add an expense to see your weekly trends.'
                        : '$day · ${_currency.format(amount)}',
                    style: textStyles.itemSubtitle.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: textStyles.caption.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  _currency.format(total),
                  style: textStyles.amount.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
