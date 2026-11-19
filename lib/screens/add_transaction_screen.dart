import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/allowance_end_date_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    this.transaction,
    this.initialType = TransactionModel.expenseType,
    super.key,
  });

  final TransactionModel? transaction;
  final String initialType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const Map<String, List<String>> _categories = {
    TransactionModel.expenseType: [
      'Food',
      'Transport',
      'School',
      'Bills',
      'Shopping',
      'Other',
    ],
    TransactionModel.allowanceType: [
      'Weekly allowance',
      'Daily allowance',
      'Monthly allowance',
      'Gift',
      'Other',
    ],
  };
  static final DateFormat _dateFormat = DateFormat('d MMMM y');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _type;
  late String _category;
  late DateTime _date;
  DateTime? _periodEndDate;
  bool _showPeriodEndDateError = false;
  bool _isSaving = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _type = transaction?.type ?? widget.initialType;
    _category = transaction?.category ?? _categories[_type]!.first;
    _date = transaction?.date ?? DateTime.now();
    _periodEndDate = transaction?.periodEndDate;
    _amountController = TextEditingController(
      text: transaction == null ? '' : transaction.amount.toStringAsFixed(2),
    )..addListener(_handleAmountChanged);
    _noteController = TextEditingController(text: transaction?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.removeListener(_handleAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleAmountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3660)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _selectPeriodEndDate() async {
    final selected = await showAllowanceEndDatePicker(
      context,
      initialDate: _periodEndDate,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _periodEndDate = selected;
      _showPeriodEndDateError = false;
    });
  }

  void _setQuickPeriodEndDate(DateTime date) {
    setState(() {
      _periodEndDate = DateUtils.dateOnly(date);
      _showPeriodEndDateError = false;
    });
  }

  Future<void> _save() async {
    if (_type == TransactionModel.allowanceType &&
        _periodEndDate != null &&
        DateUtils.dateOnly(
          _periodEndDate!,
        ).isBefore(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => _showPeriodEndDateError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final wallet = context.read<WalletProvider>();
    final existing = widget.transaction;
    final transaction = TransactionModel.create(
      id: existing?.id,
      type: _type,
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      date: _type == TransactionModel.allowanceType ? DateTime.now() : _date,
      createdAt: existing?.createdAt,
      periodEndDate: _type == TransactionModel.allowanceType
          ? _periodEndDate
          : null,
    );

    setState(() => _isSaving = true);
    try {
      if (existing == null) {
        await wallet.addTransaction(transaction);
      } else {
        await wallet.updateTransaction(transaction);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? '${_type == TransactionModel.expenseType ? 'Expense' : 'Allowance'} saved.'
                : 'Transaction updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
    final isAllowance = _type == TransactionModel.allowanceType;
    final semanticColors =
        theme.extension<AppTransactionColors>() ??
        AppTransactionColors(
          expense: colors.error,
          income: colors.tertiary,
          transport: colors.primary,
          school: colors.tertiary,
          neutral: colors.onSurfaceVariant,
        );
    final amountColor = isAllowance
        ? semanticColors.income
        : semanticColors.expense;
    final categories = [
      ..._categories[_type]!,
      if (!_categories[_type]!.contains(_category)) _category,
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: colors.surfaceContainerLow,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: colors.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${_isEditing ? 'Edit' : 'Add'} '
                        '${isAllowance ? 'Allowance' : 'Expense'}',
                        style: textStyles.screenTitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAllowance ? 'AMOUNT RECEIVED' : 'AMOUNT SPENT',
                  textAlign: TextAlign.center,
                  style: textStyles.fieldLabel.copyWith(
                    color: amountColor,
                    fontSize: 11,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, _) {
                    final displayedAmount = _amountController.text.isEmpty
                        ? '0.00'
                        : _amountController.text;
                    final fieldWidth = (displayedAmount.length * 28.0 + 8)
                        .clamp(72.0, 400.0)
                        .toDouble();
                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₱',
                              style: textStyles.largeAmount.copyWith(
                                color: colors.onSurface,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                key: const ValueKey('transaction-amount'),
                                controller: _amountController,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                style: textStyles.largeAmount.copyWith(
                                  color: colors.onSurface,
                                  fontSize: 48,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  hintStyle: textStyles.largeAmount.copyWith(
                                    color: colors.onSurface,
                                    fontSize: 48,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  errorStyle: textStyles.caption.copyWith(
                                    color: colors.error,
                                  ),
                                ),
                                validator: (value) {
                                  final amount = double.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  if (amount == null ||
                                      !amount.isFinite ||
                                      amount <= 0) {
                                    return 'Enter an amount greater than zero.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldLabel(
                        text: isAllowance ? 'SOURCE' : 'CATEGORY',
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.primary,
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category == 'Other' && !isAllowance
                                      ? 'Others'
                                      : category,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      if (!isAllowance) ...[
                        const SizedBox(height: 14),
                        _FieldLabel(
                          text: 'DATE',
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Material(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            key: const ValueKey('transaction-date'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: _selectDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _dateLabel(),
                                      style: textStyles.itemTitle.copyWith(
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (isAllowance) ...[
                        const SizedBox(height: 14),
                        _FieldLabel(
                          text: 'ALLOWANCE ENDS ON',
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Material(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            key: const ValueKey('allowance-period-end-date'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: _selectPeriodEndDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _periodEndDate == null
                                          ? 'Optional — select a date'
                                          : DateFormat(
                                              'EEE, d MMM yyyy',
                                            ).format(_periodEndDate!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textStyles.itemTitle.copyWith(
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (_periodEndDate != null)
                                    IconButton(
                                      tooltip: 'Clear end date',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(() {
                                        _periodEndDate = null;
                                        _showPeriodEndDateError = false;
                                      }),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: colors.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_showPeriodEndDateError) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Choose today or a later date.',
                            style: textStyles.caption.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _periodQuickPick(
                              context,
                              label: '1 week',
                              date: DateTime.now().add(const Duration(days: 7)),
                            ),
                            _periodQuickPick(
                              context,
                              label: '2 weeks',
                              date: DateTime.now().add(
                                const Duration(days: 14),
                              ),
                            ),
                            _periodQuickPick(
                              context,
                              label: '1 month',
                              date: DateUtils.addMonthsToMonthDate(
                                DateUtils.dateOnly(DateTime.now()),
                                1,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      _FieldLabel(
                        text: isAllowance ? 'NOTES' : 'DESCRIPTION (OPTIONAL)',
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _noteController,
                        maxLength: 100,
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a little detail',
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      textStyle: textStyles.buttonLabel,
                    ),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? 'Save changes'
                                : isAllowance
                                ? 'Save Allowance'
                                : 'Save Expense',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    if (_date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day) {
      return 'Today, ${_dateFormat.format(_date)}';
    }
    return DateFormat('EEEE, d MMMM y').format(_date);
  }

  Widget _periodQuickPick(
    BuildContext context, {
    required String label,
    required DateTime date,
  }) {
    final colors = Theme.of(context).colorScheme;
    final selected =
        _periodEndDate != null && DateUtils.isSameDay(_periodEndDate, date);
    return ActionChip(
      label: Text(label),
      onPressed: () => _setQuickPeriodEndDate(date),
      backgroundColor: selected
          ? colors.primaryContainer
          : colors.surfaceContainerLow,
      labelStyle: AppTextStyles.of(context).chipLabel.copyWith(
        color: selected ? colors.onPrimaryContainer : colors.primary,
      ),
      side: BorderSide(color: colors.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyles = AppTextStyles.of(context);
    return Text(text, style: textStyles.fieldLabel.copyWith(color: color));
  }
}
