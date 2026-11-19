import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';
import '../widgets/insight_row.dart';
import '../widgets/screen_header.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'Insights'),
            Expanded(
              child: Consumer2<WalletProvider, BudgetProvider>(
                builder: (context, wallet, budgets, _) {
                  final insights = InsightsService.generateInsights(
                    transactions: wallet.transactions,
                    budgets: budgets.budgets,
                    allowancePeriodEndDate: wallet.allowancePeriodEndDate,
                    now: DateTime.now(),
                  );
                  return RefreshIndicator(
                    onRefresh: () => Future.wait([
                      wallet.loadTransactions(),
                      budgets.loadBudgets(),
                    ]),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppLayout.screenContentPadding,
                      children: [
                        if (wallet.loadError != null ||
                            budgets.loadError != null)
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Could not load all insights. Pull down to try again.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          )
                        else if (insights.isEmpty)
                          const _EmptyInsights()
                        else
                          for (
                            var index = 0;
                            index < insights.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: InsightRow(insight: insights[index]),
                              ),
                            ),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 34, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Your insights are on the way',
              textAlign: TextAlign.center,
              style: textStyles.itemTitle,
            ),
            const SizedBox(height: 6),
            Text(
              'Add a few expenses and your insights will appear here.',
              textAlign: TextAlign.center,
              style: textStyles.itemSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}
