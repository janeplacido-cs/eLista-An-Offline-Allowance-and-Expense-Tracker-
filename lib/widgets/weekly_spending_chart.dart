import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weekly_spending_summary.dart';
import '../theme/app_theme.dart';

class WeeklySpendingChart extends StatelessWidget {
  const WeeklySpendingChart({
    required this.summary,
    this.compact = false,
    this.title = 'Daily spending',
    super.key,
  });

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final WeeklySpendingSummary summary;
  final bool compact;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    final highestIndex = summary.highestSpendingDayIndex;
    final maximum = summary.dailySpending.reduce(math.max);
    final maxY = maximum == 0 ? 10.0 : maximum * 1.25;
    final interval = maxY / 4;
    final axisCurrency = NumberFormat.compactCurrency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textStyles.sectionHeader),
            const SizedBox(height: 12),
            SizedBox(
              height: compact ? 158 : 224,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 0.6),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: !compact,
                        reservedSize: compact ? 0 : 44,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            axisCurrency.format(value),
                            style: textStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _weekdayLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              _weekdayLabels[index],
                              style: textStyles.caption.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(summary.dailySpending.length, (
                    index,
                  ) {
                    final isHighest = index == highestIndex;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: summary.dailySpending[index],
                          width: 18,
                          color: isHighest
                              ? colors.primary
                              : colors.primaryContainer,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 350),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
