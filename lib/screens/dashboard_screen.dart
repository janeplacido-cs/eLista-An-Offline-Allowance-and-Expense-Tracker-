import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_spending_chart.dart';
import '../widgets/allowance_end_date_picker.dart';
import '../widgets/allowance_period_card.dart';
import '../widgets/insights_preview_card.dart';
import '../widgets/remaining_balance_card.dart';
import '../widgets/screen_header.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'statistics_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer3<WalletProvider, BudgetProvider, ProfileProvider>(
          builder: (context, wallet, budgets, profile, _) {
            final displayName = profile.name.trim();
            final title = displayName.isEmpty ? 'Hi there' : 'Hi, $displayName';
            final currentAllowance = wallet.currentAllowance;
            final periodEndDate = currentAllowance?.periodEndDate;
            final insights = InsightsService.generateInsights(
              transactions: wallet.transactions,
              budgets: budgets.budgets,
              allowancePeriodEndDate: wallet.allowancePeriodEndDate,
              now: DateTime.now(),
            );
            return Column(
              children: [
                ScreenHeader(title: title),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: wallet.loadTransactions,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppLayout.screenContentPadding,
                      children: [
                        RemainingBalanceCard(balance: wallet.remainingBalance),
                        if (periodEndDate != null) ...[
                          const SizedBox(height: 14),
                          AllowancePeriodCard(
                            startDate: currentAllowance!.date,
                            endDate: periodEndDate,
                            remainingBalance: wallet.remainingBalance,
                            todayExpenses: wallet.todayExpenses,
                            onAddAllowance: () => _openAddTransaction(
                              context,
                              TransactionModel.allowanceType,
                            ),
                            onExtendPeriod: () =>
                                _extendAllowancePeriod(context, wallet),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openAddTransaction(
                                  context,
                                  TransactionModel.allowanceType,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Allowance'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.tertiary,
                                  ),
                                  foregroundColor: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openAddTransaction(
                                  context,
                                  TransactionModel.expenseType,
                                ),
                                icon: const Icon(Icons.remove_rounded),
                                label: const Text('Add Expense'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        InsightsPreviewCard(
                          insights: insights.take(3).toList(growable: false),
                          onSeeAll: () => _openInsights(context),
                        ),
                        const SizedBox(height: 14),
                        DashboardSpendingChart(
                          transactions: wallet.transactions,
                          onOpenStatistics: () => _openStatistics(context),
                        ),
                        const SizedBox(height: 16),
                        if (wallet.loadError != null)
                          Card(
                            color: theme.colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Could not load transactions. Pull down to try again.',
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          )
                        else
                          _WeeklyActivityCard(
                            transactions: wallet.transactions,
                            onSeeAll: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ),
                          ),
                      ],
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

  void _openAddTransaction(BuildContext context, String type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
  }

  void _openStatistics(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StatisticsScreen()));
  }

  void _openInsights(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const InsightsScreen()));
  }

  Future<void> _extendAllowancePeriod(
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
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not extend allowance period: $error')),
      );
    }
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({
    required this.transactions,
    required this.onSeeAll,
  });

  final List<TransactionModel> transactions;
  final VoidCallback onSeeAll;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final weekStart = todayStart.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final allowance = _totalFor(
      TransactionModel.allowanceType,
      weekStart,
      weekEnd,
    );
    final expenses = _totalFor(
      TransactionModel.expenseType,
      weekStart,
      weekEnd,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: AppTextStyles.of(context).sectionHeader,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This Week',
                    style: AppTextStyles.of(context).itemTitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active Period',
                    style: AppTextStyles.of(
                      context,
                    ).chipLabel.copyWith(color: colors.primary, fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _WeeklyTotalRow(
              label: 'Allowance',
              amount: '+${_currency.format(allowance)}',
              icon: Icons.trending_up_rounded,
              color: colors.tertiary,
            ),
            _WeeklyTotalRow(
              label: 'Expenses',
              amount: '−${_currency.format(expenses)}',
              icon: Icons.trending_down_rounded,
              color: colors.error,
            ),
          ],
        ),
      ),
    );
  }

  double _totalFor(String type, DateTime start, DateTime end) {
    return transactions
        .where(
          (transaction) =>
              transaction.type == type &&
              !transaction.date.isBefore(start) &&
              transaction.date.isBefore(end),
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }
}

class _WeeklyTotalRow extends StatelessWidget {
  const _WeeklyTotalRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: textStyles.itemSubtitle)),
          Text(amount, style: textStyles.amount.copyWith(color: color)),
        ],
      ),
    );
  }
}
