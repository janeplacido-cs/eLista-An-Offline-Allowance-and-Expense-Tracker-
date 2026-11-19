import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _HistoryFilter { all, expenses, allowance }

class _HistoryScreenState extends State<HistoryScreen> {
  static final DateFormat _dateFormat = DateFormat('d MMMM y');
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  _HistoryFilter _filter = _HistoryFilter.all;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, wallet, _) {
            return Column(
              children: [
                if (_isSearching)
                  Padding(
                    padding: AppLayout.headerPadding,
                    child: SizedBox(
                      height: AppLayout.headerRowHeight,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Close search',
                            onPressed: _closeSearch,
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: colors.onSurface,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Search transactions',
                                isDense: true,
                                suffixIcon: ValueListenableBuilder<String>(
                                  valueListenable: _searchQuery,
                                  builder: (context, query, _) => query.isEmpty
                                      ? const SizedBox.shrink()
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchQuery.value = '';
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                ),
                              ),
                              onChanged: (value) => _searchQuery.value = value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ScreenHeader(
                    title: 'History',
                    trailing: IconButton(
                      tooltip: 'Search transactions',
                      onPressed: () => setState(() => _isSearching = true),
                      icon: Icon(Icons.search_rounded, color: colors.primary),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppLayout.screenHorizontalPadding,
                    AppLayout.headerContentGap,
                    AppLayout.screenHorizontalPadding,
                    12,
                  ),
                  child: Row(
                    children: [
                      _filterChip('All', _HistoryFilter.all),
                      const SizedBox(width: 8),
                      _filterChip('Expenses', _HistoryFilter.expenses),
                      const SizedBox(width: 8),
                      _filterChip('Allowance', _HistoryFilter.allowance),
                    ],
                  ),
                ),
                if (wallet.loadError != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppLayout.screenHorizontalPadding,
                      0,
                      AppLayout.screenHorizontalPadding,
                      8,
                    ),
                    child: Text(
                      'Could not refresh transactions. Pull down to try again.',
                      style: textStyles.caption.copyWith(color: colors.error),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: wallet.loadTransactions,
                    child: ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, query, _) {
                        if (wallet.loadError != null &&
                            wallet.transactions.isEmpty) {
                          return _HistoryMessage(
                            icon: Icons.error_outline_rounded,
                            message: 'Could not load transaction history.',
                            actionLabel: 'Try again',
                            onAction: wallet.loadTransactions,
                          );
                        }
                        if (wallet.isLoading && wallet.transactions.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final transactions = _filterTransactions(
                          wallet.transactions,
                          query,
                        );
                        if (transactions.isEmpty) {
                          return CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyHistory(
                                  hasAnyTransactions:
                                      wallet.transactions.isNotEmpty,
                                  onAdd: () => _openEditor(context),
                                ),
                              ),
                            ],
                          );
                        }

                        final items = _buildListItems(transactions);
                        return CustomScrollView(
                          key: const PageStorageKey('history-list'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                AppLayout.screenHorizontalPadding,
                                0,
                                AppLayout.screenHorizontalPadding,
                                24,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = items[index];
                                  if (item.date != null) {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        2,
                                        12,
                                        2,
                                        6,
                                      ),
                                      child: Text(
                                        _dayLabel(item.date!),
                                        style: textStyles.sectionHeader,
                                      ),
                                    );
                                  }

                                  final transaction = item.transaction!;
                                  final id = transaction.id;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 1,
                                    ),
                                    child: Dismissible(
                                      key: ValueKey(
                                        'history-${id ?? transaction.createdAt.microsecondsSinceEpoch}',
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) =>
                                          _confirmDelete(context, transaction),
                                      onDismissed: (_) => _deleteTransaction(
                                        context,
                                        transaction,
                                      ),
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: colors.error,
                                        ),
                                      ),
                                      child: TransactionTile(
                                        key: ValueKey(
                                          'transaction-${transaction.id}',
                                        ),
                                        transaction: transaction,
                                        onEdit: () =>
                                            _openEditor(context, transaction),
                                        onDelete: () => _deleteWithConfirmation(
                                          context,
                                          transaction,
                                        ),
                                      ),
                                    ),
                                  );
                                }, childCount: items.length),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _filterChip(String label, _HistoryFilter filter) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
    final selected = _filter == filter;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, maxLines: 1)),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: textStyles.chipLabel.copyWith(
          color: selected ? colors.onPrimary : colors.primary,
        ),
        selectedColor: colors.primary,
        backgroundColor: colors.primaryContainer.withValues(alpha: 0.55),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    final results = transactions.where((transaction) {
      final matchesFilter = switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.expenses => transaction.isExpense,
        _HistoryFilter.allowance => !transaction.isExpense,
      };
      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;
      return transaction.category.toLowerCase().contains(normalizedQuery) ||
          (transaction.note?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();

    results.sort((first, second) {
      final dateOrder = second.date.compareTo(first.date);
      if (dateOrder != 0) return dateOrder;
      final createdOrder = second.createdAt.compareTo(first.createdAt);
      if (createdOrder != 0) return createdOrder;
      return (second.id ?? 0).compareTo(first.id ?? 0);
    });
    return results;
  }

  List<_HistoryListItem> _buildListItems(List<TransactionModel> transactions) {
    final items = <_HistoryListItem>[];
    DateTime? activeDate;
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (activeDate == null || !_sameDay(activeDate, date)) {
        activeDate = date;
        items.add(_HistoryListItem.header(date));
      }
      items.add(_HistoryListItem.transaction(transaction));
    }
    return items;
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return _dateFormat.format(date);
  }

  void _closeSearch() {
    _searchController.clear();
    _searchQuery.value = '';
    setState(() => _isSearching = false);
  }

  static Future<void> _openEditor(
    BuildContext context, [
    TransactionModel? transaction,
  ]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );
  }

  static Future<bool> _confirmDelete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text(
              'This transaction will be permanently removed.',
            ),
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
        ) ??
        false;
  }

  static Future<void> _deleteWithConfirmation(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    if (!await _confirmDelete(context, transaction) || !context.mounted) {
      return;
    }
    await _deleteTransaction(context, transaction);
  }

  static Future<void> _deleteTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final id = transaction.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete a transaction without an ID.'),
        ),
      );
      return;
    }

    try {
      await context.read<WalletProvider>().deleteTransaction(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete transaction: $error')),
      );
    }
  }
}

class _HistoryListItem {
  const _HistoryListItem.header(this.date) : transaction = null;

  const _HistoryListItem.transaction(this.transaction) : date = null;

  final DateTime? date;
  final TransactionModel? transaction;
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasAnyTransactions, required this.onAdd});

  final bool hasAnyTransactions;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = AppTextStyles.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyTransactions
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 48,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text('No transactions found', style: textStyles.itemTitle),
            if (!hasAnyTransactions) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onAdd,
                child: const Text('Add transaction'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
