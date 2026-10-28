import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/balance_item.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';
import '../widgets/empty_state.dart';

/// 资产负债页：净资产卡 + 资产/负债条目管理
class BalancePage extends StatelessWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final assets = provider.balanceItems.where((i) => i.isAsset).toList();
    final liabilities = provider.balanceItems.where((i) => !i.isAsset).toList();
    final totals = provider.totals;

    return Scaffold(
      appBar: AppBar(title: const Text('资产负债表')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '净资产',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmtMoney(totals.netWorth),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '总资产 ${fmtMoney(totals.assets)} · 总负债 ${fmtMoney(totals.liabilities)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SectionHeader(
            title: '资产（${assets.length}）',
            onAdd: () => _showAddDialog(context, 'asset'),
          ),
          if (assets.isEmpty)
            const EmptyState(
              variant: EmptyStateVariant.compact,
              config: EmptyStateConfig(
                icon: Icons.account_balance_outlined,
                title: '还没有资产条目',
                subtitle: '点右侧 + 开始记录',
              ),
            ),
          for (final item in assets) _BalanceTile(item: item),
          _SectionHeader(
            title: '负债（${liabilities.length}）',
            onAdd: () => _showAddDialog(context, 'liability'),
          ),
          if (liabilities.isEmpty)
            const EmptyState(
              variant: EmptyStateVariant.compact,
              config: EmptyStateConfig(
                icon: Icons.credit_card_off_outlined,
                title: '还没有负债条目',
                subtitle: '点右侧 + 开始记录',
              ),
            ),
          for (final item in liabilities) _BalanceTile(item: item),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, String kind) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(kind == 'asset' ? '添加资产' : '添加负债'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '名称（如：活期存款）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '金额',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;

    final raw = amountCtrl.text.trim();
    final valid = RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw);
    final amount = double.tryParse(raw);
    final name = nameCtrl.text.trim();
    if (name.isEmpty || !valid || amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称不能为空，金额需大于 0')));
      return;
    }
    await context.read<FinanceProvider>().addBalanceItem(
      kind: kind,
      name: name,
      amount: double.parse(amount.toStringAsFixed(2)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final BalanceItem item;

  const _BalanceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<FinanceProvider>();
    return Dismissible(
      key: ValueKey('bi-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除条目'),
          content: Text('确定删除「${item.name}」吗？'),
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
      ),
      onDismissed: (_) => provider.deleteBalanceItem(item.id!),
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: ListTile(
        leading: Icon(
          item.isAsset
              ? Icons.account_balance_wallet_outlined
              : Icons.credit_card_off_outlined,
          color: item.isAsset ? scheme.primary : scheme.error,
        ),
        title: Text(item.name),
        trailing: Text(
          fmtMoney(item.amount),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
