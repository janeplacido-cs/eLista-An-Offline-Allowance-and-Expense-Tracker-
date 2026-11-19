import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class DashboardSpendingChart extends StatefulWidget {
  const DashboardSpendingChart({
    required this.transactions,
    required this.onOpenStatistics,
    super.key,
  });

  final List<TransactionModel> transactions;
  final VoidCallback onOpenStatistics;

  @override
  State<DashboardSpendingChart> createState() => _DashboardSpendingChartState();
}

enum _SpendingPeriod { week, month, allTime }

class _DashboardSpendingChartState extends State<DashboardSpendingChart> {
  static const _periodLabels = {
    _SpendingPeriod.week: 'This week',
    _SpendingPeriod.month: 'This month',
    _SpendingPeriod.allTime: 'All time',
  };
  static const _weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  _SpendingPeriod _period = _SpendingPeriod.week;
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
    final series = _buildSeries();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Spending Statistics',
                style: textStyles.sectionHeader,
              ),
            ),
            IconButton(
              onPressed: widget.onOpenStatistics,
              tooltip: 'Open statistics',
              icon: Icon(Icons.tune_rounded, color: colors.primary, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final period in _SpendingPeriod.values)
              Expanded(
                child: Center(
                  child: ChoiceChip(
                    label: Text(_periodLabels[period]!),
                    selected: _period == period,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: textStyles.chipLabel.copyWith(
                      color: _period == period
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: colors.primary,
                    backgroundColor: colors.primaryContainer.withValues(
                      alpha: 0.65,
                    ),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onSelected: (_) {
                      setState(() {
                        _period = period;
                        _offset = 0;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_period == _SpendingPeriod.allTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text(series.rangeLabel, style: textStyles.caption),
            ),
          )
        else
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Previous period',
                onPressed: () => setState(() => _offset--),
                icon: Icon(Icons.chevron_left_rounded, color: colors.primary),
              ),
              Expanded(
                child: Text(
                  series.rangeLabel,
                  textAlign: TextAlign.center,
                  style: textStyles.caption.copyWith(color: colors.onSurface),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Next period',
                onPressed: _offset == 0
                    ? null
                    : () => setState(() => _offset++),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _offset == 0 ? colors.outlineVariant : colors.primary,
                ),
              ),
            ],
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 8),
            child: SizedBox(
              height: 126,
              child: _SpendingBarChart(series: series),
            ),
          ),
        ),
      ],
    );
  }

  _SpendingSeries _buildSeries() {
    final today = DateTime.now();
    final expenses = widget.transactions.where(
      (transaction) => transaction.type == TransactionModel.expenseType,
    );

    if (_period == _SpendingPeriod.week) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: _offset * 7));
      final start = date.subtract(
        Duration(days: date.weekday - DateTime.monday),
      );
      final end = start.add(const Duration(days: 7));
      final values = List<double>.filled(7, 0);
      for (final transaction in expenses) {
        if (!transaction.date.isBefore(start) &&
            transaction.date.isBefore(end)) {
          values[transaction.date.weekday - DateTime.monday] +=
              transaction.amount;
        }
      }
      return _SpendingSeries(
        labels: _weekLabels,
        values: values,
        rangeLabel:
            '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end.subtract(const Duration(days: 1)))}',
      );
    }

    if (_period == _SpendingPeriod.month) {
      final start = DateTime(today.year, today.month + _offset);
      final nextMonth = DateTime(start.year, start.month + 1);
      final weekCount = (nextMonth.difference(start).inDays + 6) ~/ 7;
      final values = List<double>.filled(weekCount, 0);
      for (final transaction in expenses) {
        if (!transaction.date.isBefore(start) &&
            transaction.date.isBefore(nextMonth)) {
          values[(transaction.date.day - 1) ~/ 7] += transaction.amount;
        }
      }
      return _SpendingSeries(
        labels: List.generate(weekCount, (index) => 'W${index + 1}'),
        values: values,
        rangeLabel: DateFormat('MMMM yyyy').format(start),
      );
    }

    final endOfToday = DateTime(today.year, today.month, today.day + 1);
    final expenseList = expenses
        .where((transaction) => transaction.date.isBefore(endOfToday))
        .toList(growable: false);
    final startYear = expenseList.isEmpty
        ? today.year
        : expenseList.map((item) => item.date.year).reduce(math.min);
    final yearCount = today.year - startYear + 1;
    final yearsPerGroup = (yearCount + 6) ~/ 7;
    final groupCount = (yearCount + yearsPerGroup - 1) ~/ yearsPerGroup;
    final values = List<double>.filled(groupCount, 0);
    for (final transaction in expenseList) {
      final group = (transaction.date.year - startYear) ~/ yearsPerGroup;
      values[group] += transaction.amount;
    }
    final labels = List.generate(groupCount, (index) {
      final firstYear = startYear + index * yearsPerGroup;
      final lastYear = math.min(today.year, firstYear + yearsPerGroup - 1);
      return firstYear == lastYear
          ? DateFormat('yy').format(DateTime(firstYear))
          : '${DateFormat('yy').format(DateTime(firstYear))}–${DateFormat('yy').format(DateTime(lastYear))}';
    });
    final rangeLabel = expenseList.isEmpty
        ? 'No expenses recorded'
        : '${DateFormat('MMM yyyy').format(DateTime(startYear))} – ${DateFormat('MMM yyyy').format(today)}';
    return _SpendingSeries(
      labels: labels,
      values: values,
      rangeLabel: rangeLabel,
    );
  }
}

class _SpendingSeries {
  const _SpendingSeries({
    required this.labels,
    required this.values,
    required this.rangeLabel,
  });

  final List<String> labels;
  final List<double> values;
  final String rangeLabel;
}

class _SpendingBarChart extends StatelessWidget {
  const _SpendingBarChart({required this.series});

  final _SpendingSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    final maximum = series.values.fold<double>(0, math.max);
    final maxY = maximum == 0 ? 10.0 : maximum * 1.25;
    final interval = maxY / 3;
    final currency = NumberFormat.compactCurrency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    return BarChart(
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
              showTitles: true,
              reservedSize: 36,
              interval: interval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  currency.format(value),
                  style: textStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= series.labels.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    series.labels[index],
                    style: textStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(series.values.length, (index) {
          final highest =
              series.values.isNotEmpty &&
              series.values[index] == series.values.reduce(math.max) &&
              series.values[index] > 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: series.values[index],
                width: series.values.length > 10 ? 7 : 12,
                color: highest
                    ? colors.primary
                    : colors.tertiary.withValues(alpha: 0.65),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
