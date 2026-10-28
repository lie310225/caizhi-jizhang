import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../models/recurring_bill.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';
import '../app_tokens.dart';
import '../widgets/empty_state.dart';
import 'add_recurring_sheet.dart';

// ==================================================================
// 组件主体
// ==================================================================
/// 周期账单：固定房租 / 房贷 / 订阅，到期一键记账
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final all = provider.recurringBills;
    final due = provider.monthDueRecurrings;

    return Scaffold(
      appBar: AppBar(title: const Text('周期账单')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddRecurringSheet(context),
        elevation: 6,
        backgroundColor: AppSemanticColors.income,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          '新建账单',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              monthLabel(provider.selectedMonth),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (due.isNotEmpty) ...[
            _DueBanner(count: due.length),
            for (final bill in due)
              _RecurringTile(
                bill: bill,
                dueThisMonth: true,
                onApply: () => provider.applyRecurring(bill),
              ),
            _GroupTitle(title: '全部账单', count: all.length),
          ],
          if (all.isEmpty)
            SizedBox(
              height: 320,
              child: EmptyState.preset(
                const EmptyStateConfig(
                  icon: Icons.event_repeat_outlined,
                  title: '还没有周期账单',
                  subtitle: '把房租、房贷、会员订阅记成模板，到日子一点即记账',
                ),
              ),
            )
          else
            for (final bill in all)
              _RecurringTile(
                bill: bill,
                dueThisMonth: due.any((d) => d.id == bill.id),
                onApply: () => provider.applyRecurring(bill),
              ),
        ],
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  final int count;

  const _DueBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: AppShadows.soft(AppSemanticColors.income),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '本月有 $count 笔账单到期，记得记账',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String title;
  final int count;

  const _GroupTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            '$count 项',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringBill bill;
  final bool dueThisMonth;
  final VoidCallback onApply;

  const _RecurringTile({
    required this.bill,
    required this.dueThisMonth,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = bill.type == TxType.income;
    final color = AppCategoryColors.of(bill.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.l),
          onTap: () => _showActions(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(
                color: dueThisMonth
                    ? AppSemanticColors.income.withValues(alpha: 0.4)
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppCategoryColors.tintOf(bill.category),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Icon(
                    kCategoryIcons[bill.category] ??
                        Icons.event_repeat_outlined,
                    size: 21,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: bill.active
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '每月 ${bill.dayOfMonth} 日 · ${bill.category}'
                        '${bill.active ? '' : ' · 已停用'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${fmtMoney(bill.amount)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isIncome
                            ? AppSemanticColors.income
                            : AppSemanticColors.expense,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (dueThisMonth)
                      FilledButton(
                        onPressed: onApply,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: AppSemanticColors.income,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('记账'),
                      )
                    else
                      Text(
                        '本月已记',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final provider = context.read<FinanceProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                bill.active
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              title: Text(bill.active ? '停用此账单' : '启用此账单'),
              onTap: () {
                provider.toggleRecurring(bill, !bill.active);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                '删除账单',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteRecurring(bill.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
