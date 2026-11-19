import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final palette =
        theme.extension<AppBudgetColors>() ??
        AppBudgetColors.forBrightness(theme.brightness);

    return Scaffold(
      body: SafeArea(
        child: Consumer2<BudgetProvider, WalletProvider>(
          builder: (context, budgets, wallet, _) {
            if ((budgets.isLoading || wallet.isLoading) &&
                budgets.budgets.isEmpty &&
                wallet.transactions.isEmpty) {
              return Column(
                children: [
                  ScreenHeader(
                    title: 'Budget',
                    trailing: IconButton(
                      tooltip: 'Refresh budget data',
                      onPressed: () => _refresh(budgets, wallet),
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            final categories = _categorySummaries(budgets, wallet);
            return Column(
              children: [
                ScreenHeader(
                  title: 'Budget',
                  trailing: IconButton(
                    tooltip: 'Refresh budget data',
                    onPressed: () => _refresh(budgets, wallet),
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _refresh(budgets, wallet),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppLayout.screenContentPadding,
                      children: [
                        _AllowanceSummaryCard(
                          allowance: wallet.totalAllowance,
                          expenses: wallet.totalExpenses,
                          remaining: wallet.remainingBalance,
                          palette: palette,
                        ),
                        const SizedBox(height: 28),
                        _BudgetOverview(
                          allowance: wallet.totalAllowance,
                          expenses: wallet.totalExpenses,
                          remaining: wallet.remainingBalance,
                          palette: palette,
                        ),
                        const SizedBox(height: 38),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Category Breakdown',
                                style: textStyles.sectionHeader.copyWith(
                                  color: palette.navy,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('add-budget'),
                              tooltip: 'Set a budget',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _editBudget(context),
                              icon: const Icon(Icons.add_rounded),
                              color: palette.navy,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (categories.isEmpty)
                          _CategoryEmptyState(palette: palette)
                        else
                          for (
                            var index = 0;
                            index < categories.length;
                            index++
                          ) ...[
                            _CategoryTile(
                              data: categories[index],
                              color: palette.categoryColor(
                                categories[index].category,
                                index,
                              ),
                              palette: palette,
                              onTap: categories[index].budget == null
                                  ? null
                                  : () => _editBudget(
                                      context,
                                      categories[index].budget,
                                    ),
                              onLongPress: categories[index].budget == null
                                  ? null
                                  : () => _confirmDelete(
                                      context,
                                      categories[index].budget!,
                                    ),
                            ),
                            if (index != categories.length - 1)
                              const SizedBox(height: 22),
                          ],
                        if (budgets.loadError != null ||
                            wallet.loadError != null) ...[
                          const SizedBox(height: 16),
                          _LoadErrorNotice(palette: palette),
                        ],
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

  static Future<void> _refresh(
    BudgetProvider budgets,
    WalletProvider wallet,
  ) async {
    await Future.wait([budgets.loadBudgets(), wallet.loadTransactions()]);
  }

  static List<_CategoryBudgetData> _categorySummaries(
    BudgetProvider budgets,
    WalletProvider wallet,
  ) {
    final categories = <String>{
      ...wallet.transactions
          .where((transaction) => transaction.isExpense)
          .map((transaction) => transaction.category),
      ...budgets.budgets
          .where((budget) => !budget.isOverall)
          .map((budget) => budget.category!),
    }.toList();

    final categoryOrder = {
      for (
        var index = 0;
        index < TransactionModel.expenseCategories.length;
        index++
      )
        TransactionModel.expenseCategories[index]: index,
    };
    categories.sort((left, right) {
      final leftOrder = categoryOrder[left] ?? categoryOrder.length;
      final rightOrder = categoryOrder[right] ?? categoryOrder.length;
      return leftOrder == rightOrder
          ? left.compareTo(right)
          : leftOrder.compareTo(rightOrder);
    });

    return categories
        .map((category) {
          final categoryBudgets =
              budgets.budgets
                  .where((budget) => budget.category == category)
                  .toList()
                ..sort((left, right) {
                  final leftPriority = left.period == BudgetModel.weeklyPeriod
                      ? 0
                      : 1;
                  final rightPriority = right.period == BudgetModel.weeklyPeriod
                      ? 0
                      : 1;
                  return leftPriority.compareTo(rightPriority);
                });
          final budget = categoryBudgets.isEmpty ? null : categoryBudgets.first;
          final spent = budget == null
              ? wallet.transactions
                    .where(
                      (transaction) =>
                          transaction.isExpense &&
                          transaction.category == category,
                    )
                    .fold<double>(
                      0,
                      (total, transaction) => total + transaction.amount,
                    )
              : budgets.spentFor(budget, wallet.transactions);
          final progress = budget == null || budget.limitAmount <= 0
              ? 0.0
              : (spent / budget.limitAmount).clamp(0.0, 1.0).toDouble();

          return _CategoryBudgetData(
            category: category,
            budget: budget,
            spent: spent,
            progress: progress,
          );
        })
        .toList(growable: false);
  }

  static Future<void> _editBudget(
    BuildContext context, [
    BudgetModel? budget,
  ]) async {
    final result = await showDialog<BudgetModel>(
      context: context,
      builder: (_) => _BudgetFormDialog(budget: budget),
    );
    if (result == null || !context.mounted) return;

    try {
      await context.read<BudgetProvider>().saveBudget(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(budget == null ? 'Budget saved.' : 'Budget updated.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save budget: $error')));
    }
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    BudgetModel budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text('This spending limit will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final id = budget.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete a budget without an ID.')),
      );
      return;
    }

    try {
      await context.read<BudgetProvider>().deleteBudget(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete budget: $error')),
      );
    }
  }
}

class _CategoryBudgetData {
  const _CategoryBudgetData({
    required this.category,
    required this.budget,
    required this.spent,
    required this.progress,
  });

  final String category;
  final BudgetModel? budget;
  final double spent;
  final double progress;
}

class _AllowanceSummaryCard extends StatelessWidget {
  const _AllowanceSummaryCard({
    required this.allowance,
    required this.expenses,
    required this.remaining,
    required this.palette,
  });

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final double allowance;
  final double expenses;
  final double remaining;
  final AppBudgetColors palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.summaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _SummaryAmountRow(
              label: 'Total Allowance',
              amount: _currency.format(allowance),
              color: palette.navy,
            ),
            const SizedBox(height: 6),
            _SummaryAmountRow(
              label: 'Total Expenses',
              amount: _currency.format(expenses),
              color: palette.expense,
            ),
            const SizedBox(height: 6),
            _SummaryAmountRow(
              label: 'Remaining Balance',
              amount: _currency.format(remaining),
              color: remaining < 0 ? palette.expense : palette.remaining,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryAmountRow extends StatelessWidget {
  const _SummaryAmountRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    final style = textStyles.itemSubtitle.copyWith(
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            amount,
            maxLines: 1,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  const _BudgetOverview({
    required this.allowance,
    required this.expenses,
    required this.remaining,
    required this.palette,
  });

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final double allowance;
  final double expenses;
  final double remaining;
  final AppBudgetColors palette;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    final expenseFraction = allowance <= 0
        ? 0.0
        : (expenses / allowance).clamp(0.0, 1.0).toDouble();
    final expensePercent = (expenseFraction * 100).round();
    final remainingPercent = 100 - expensePercent;

    return Row(
      children: [
        SizedBox.square(
          key: const ValueKey('budget-donut'),
          dimension: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(92),
                painter: _BudgetDonutPainter(
                  expenseFraction: expenseFraction,
                  expenseColor: palette.navy,
                  remainingColor: palette.cyan,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currency.format(remaining),
                        maxLines: 1,
                        style: textStyles.amount.copyWith(
                          color: remaining < 0 ? palette.expense : palette.navy,
                        ),
                      ),
                      Text(
                        'left',
                        style: textStyles.caption.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _OverviewProgressRow(
                label: 'Expenses',
                percentage: expensePercent,
                progress: expenseFraction,
                color: palette.navy,
                palette: palette,
              ),
              const SizedBox(height: 12),
              _OverviewProgressRow(
                label: 'Remaining',
                percentage: remainingPercent,
                progress: 1 - expenseFraction,
                color: palette.cyan,
                palette: palette,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetDonutPainter extends CustomPainter {
  const _BudgetDonutPainter({
    required this.expenseFraction,
    required this.expenseColor,
    required this.remainingColor,
  });

  final double expenseFraction;
  final Color expenseColor;
  final Color remainingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.1;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final ringPaint = Paint()
      ..color = remainingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, ringPaint);

    if (expenseFraction <= 0) return;
    final expensePaint = Paint()
      ..color = expenseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      6.283185307179586 * expenseFraction,
      false,
      expensePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetDonutPainter oldDelegate) {
    return oldDelegate.expenseFraction != expenseFraction ||
        oldDelegate.expenseColor != expenseColor ||
        oldDelegate.remainingColor != remainingColor;
  }
}

class _OverviewProgressRow extends StatelessWidget {
  const _OverviewProgressRow({
    required this.label,
    required this.percentage,
    required this.progress,
    required this.color,
    required this.palette,
  });

  final String label;
  final int percentage;
  final double progress;
  final Color color;
  final AppBudgetColors palette;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textStyles.caption.copyWith(color: palette.navy),
              ),
            ),
            Text(
              '$percentage%',
              style: textStyles.amount.copyWith(color: palette.navy),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _AnimatedProgressBar(
          progress: progress,
          color: color,
          trackColor: palette.track,
          height: 6,
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.data,
    required this.color,
    required this.palette,
    required this.onTap,
    required this.onLongPress,
  });

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final _CategoryBudgetData data;
  final Color color;
  final AppBudgetColors palette;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.itemTitle.copyWith(color: palette.navy),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _currency.format(data.spent),
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.amount.copyWith(color: palette.navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _AnimatedProgressBar(
              progress: data.progress,
              color: color,
              trackColor: palette.track,
              height: 7,
            ),
            const SizedBox(height: 6),
            Text(
              '${(data.progress * 100).round()}% of category budget spent',
              style: textStyles.caption.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.height,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState({required this.palette});

  final AppBudgetColors palette;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        'No category activity yet. Add an expense or set a category budget to see your breakdown.',
        style: textStyles.caption.copyWith(color: palette.muted),
      ),
    );
  }
}

class _LoadErrorNotice extends StatelessWidget {
  const _LoadErrorNotice({required this.palette});

  final AppBudgetColors palette;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return Text(
      'Some budget data could not be refreshed. Tap refresh to try again.',
      style: textStyles.caption.copyWith(color: palette.expense),
    );
  }
}

class _BudgetFormDialog extends StatefulWidget {
  const _BudgetFormDialog({this.budget});

  final BudgetModel? budget;

  @override
  State<_BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<_BudgetFormDialog> {
  static const String _overallCategory = 'Overall';
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String _category;
  late String _period;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _amountController = TextEditingController(
      text: budget == null ? '' : budget.limitAmount.toStringAsFixed(2),
    );
    _category = budget?.category ?? _overallCategory;
    _period = budget?.period ?? BudgetModel.weeklyPeriod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      BudgetModel(
        id: widget.budget?.id,
        category: _category == _overallCategory ? null : _category,
        limitAmount: double.parse(_amountController.text.trim()),
        period: _period,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return AlertDialog(
      title: Text(
        widget.budget == null ? 'Set a budget' : 'Edit budget',
        style: textStyles.sectionHeader,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'For'),
                items:
                    [
                          _overallCategory,
                          ...TransactionModel.expenseCategories,
                          if (_category != _overallCategory &&
                              !TransactionModel.expenseCategories.contains(
                                _category,
                              ))
                            _category,
                        ]
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(
                    value: BudgetModel.weeklyPeriod,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: BudgetModel.monthlyPeriod,
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _period = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('budget-limit'),
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Spending limit',
                  prefixText: '₱ ',
                  hintText: '0.00',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter a limit greater than zero.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.budget == null ? 'Save budget' : 'Save changes'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      titleTextStyle: textStyles.sectionHeader,
    );
  }
}
