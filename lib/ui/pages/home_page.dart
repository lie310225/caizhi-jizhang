import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../models/transaction_record.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';
import 'add_transaction_sheet.dart';

/// 流水首页：月份切换 + 收支汇总卡 + 按日分组流水 + 记一笔
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final records = provider.monthRecords;
    final summary = provider.monthSummary;

    final tiles = <Widget>[];
    String? lastDate;
    for (final r in records) {
      if (r.date != lastDate) {
        lastDate = r.date;
        tiles.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              dayLabel(r.date),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        );
      }
      tiles.add(_TransactionTile(record: r));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('财智记账')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: Column(
        children: [
          const _MonthHeader(),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _SummaryCell(
                    label: '收入',
                    value: summary.income,
                    color: scheme.primary,
                  ),
                  _verticalDivider(scheme),
                  _SummaryCell(
                    label: '支出',
                    value: summary.expense,
                    color: scheme.error,
                  ),
                  _verticalDivider(scheme),
                  _SummaryCell(
                    label: '结余',
                    value: summary.balance,
                    color: scheme.secondary,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 56,
                          color: scheme.outline,
                        ),
                        const SizedBox(height: 12),
                        const Text('还没有记录，点右下角记下第一笔吧'),
                      ],
                    ),
                  )
                : ListView(children: tiles),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(ColorScheme scheme) =>
      Container(width: 1, height: 28, color: scheme.outlineVariant);
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '上一月',
          onPressed: () => provider.shiftMonthBy(-1),
        ),
        Text(
          monthLabel(provider.selectedMonth),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '下一月',
          onPressed: () => provider.shiftMonthBy(1),
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmtMoney(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionRecord record;

  const _TransactionTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<FinanceProvider>();
    final isIncome = record.type == TxType.income;
    return Dismissible(
      key: ValueKey('tx-${record.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => provider.deleteTransaction(record.id!),
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            kCategoryIcons[record.category] ?? Icons.receipt_long_outlined,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(record.category),
        subtitle: record.note.isEmpty
            ? null
            : Text(record.note, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          '${isIncome ? '+' : '-'}${fmtMoney(record.amount)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isIncome ? scheme.primary : scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这笔记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
