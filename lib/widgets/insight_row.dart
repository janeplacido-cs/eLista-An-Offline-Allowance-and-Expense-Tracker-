import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/app_theme.dart';

class InsightRow extends StatelessWidget {
  const InsightRow({required this.insight, this.compact = false, super.key});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColors = theme.extension<AppStatusColors>();
    final color = switch (insight.severity) {
      InsightSeverity.good => statusColors?.success ?? colors.primary,
      InsightSeverity.warning => statusColors?.warning ?? colors.tertiary,
      InsightSeverity.info => colors.primary,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withValues(alpha: 0.13),
          foregroundColor: color,
          child: Icon(_iconFor(insight.icon), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                maxLines: compact ? 1 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: AppTextStyles.of(context).itemTitle,
              ),
              const SizedBox(height: 3),
              Text(
                insight.message,
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: AppTextStyles.of(context).itemSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(InsightIcon? icon) => switch (icon) {
    InsightIcon.trendingDown => Icons.trending_down_rounded,
    InsightIcon.category => Icons.category_outlined,
    InsightIcon.calendar => Icons.calendar_month_outlined,
    InsightIcon.budget => Icons.account_balance_wallet_outlined,
    InsightIcon.savings => Icons.savings_outlined,
    InsightIcon.average => Icons.show_chart_rounded,
    InsightIcon.highest => Icons.stacked_line_chart_rounded,
    null => Icons.lightbulb_outline_rounded,
  };
}
