import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/app_theme.dart';
import 'insight_row.dart';

class InsightsPreviewCard extends StatelessWidget {
  const InsightsPreviewCard({
    required this.insights,
    required this.onSeeAll,
    super.key,
  });

  final List<Insight> insights;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Insights', style: textStyles.sectionHeader),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (insights.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                child: Text(
                  'Add a few expenses and your insights will appear here.',
                  style: textStyles.itemSubtitle.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var index = 0; index < insights.length; index++) ...[
                if (index > 0)
                  Divider(height: 20, color: colors.outlineVariant),
                InsightRow(insight: insights[index], compact: true),
              ],
          ],
        ),
      ),
    );
  }
}
