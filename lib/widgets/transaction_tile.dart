import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final TransactionModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
    final isExpense = transaction.isExpense;
    final transactionColors =
        theme.extension<AppTransactionColors>() ??
        AppTransactionColors(
          expense: colors.error,
          income: colors.tertiary,
          transport: colors.primary,
          school: colors.tertiary,
          neutral: colors.onSurfaceVariant,
        );
    final category = transaction.category.toLowerCase();
    final accent = !isExpense
        ? transactionColors.income
        : switch (category) {
            'food' => transactionColors.expense,
            'transport' => transactionColors.transport,
            'school' => transactionColors.school,
            _ => transactionColors.neutral,
          };
    final icon = !isExpense
        ? Icons.account_balance_wallet_outlined
        : switch (category) {
            'food' => Icons.restaurant_outlined,
            'transport' => Icons.directions_bus_outlined,
            'school' => Icons.school_outlined,
            'bills' => Icons.receipt_long_outlined,
            'shopping' => Icons.shopping_bag_outlined,
            'health' => Icons.medical_services_outlined,
            'entertainment' => Icons.movie_outlined,
            _ => Icons.category_outlined,
          };
    final note = transaction.note?.trim();
    final title = note == null || note.isEmpty ? transaction.category : note;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      minLeadingWidth: 48,
      onTap: onEdit,
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: accent.withValues(alpha: 0.14),
        foregroundColor: accent,
        child: Icon(icon, size: 21),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyles.itemTitle,
      ),
      subtitle: Text(
        _timeFormat.format(transaction.date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyles.itemSubtitle,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '${isExpense ? '-' : '+'}${_currency.format(transaction.amount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyles.amount.copyWith(color: accent),
            ),
          ),
          if (onEdit != null && onDelete != null)
            PopupMenuButton<String>(
              tooltip: 'Transaction actions',
              onSelected: (action) {
                if (action == 'edit') onEdit!();
                if (action == 'delete') onDelete!();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
