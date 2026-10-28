import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../models/transaction_record.dart';
import '../../providers/finance_provider.dart';
import '../../services/article_service.dart';
import '../../services/format.dart';
import '../app_tokens.dart';
import '../widgets/empty_state.dart';
import 'add_transaction_sheet.dart';
import 'article_detail_page.dart';

/// 流水首页：渐变主卡（月份 + 结余 + 收支）+ 按日分组流水 + 记一笔
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final records = provider.monthRecords;

    final children = <Widget>[const _HeroCard()];

    if (records.isEmpty) {
      children.add(
        SizedBox(
          height: 300,
          child: EmptyState.preset(EmptyStatePresets.txEmpty),
        ),
      );
    } else {
      children.add(_SectionTitle(count: records.length));
      String? lastDate;
      for (final r in records) {
        if (r.date != lastDate) {
          lastDate = r.date;
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                dayLabel(r.date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        children.add(_TransactionTile(record: r));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('财智记账')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        elevation: 6,
        backgroundColor: AppSemanticColors.income,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('记一笔', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        children: children,
      ),
    );
  }
}

// ------------------------------------------------------------------
// 渐变主卡：视觉焦点，大数字 + 收支对照
// ------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final summary = provider.monthSummary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadows.hero(AppSemanticColors.income),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: Stack(
          children: [
            // 右上角光斑 + 左下角微弱光斑，制造球面感
            Positioned(
              right: -50,
              top: -78,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -70,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        monthLabel(provider.selectedMonth),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      _MonthArrow(
                        icon: Icons.chevron_left,
                        tooltip: '上一月',
                        onTap: () => provider.shiftMonthBy(-1),
                      ),
                      const SizedBox(width: 2),
                      _MonthArrow(
                        icon: Icons.chevron_right,
                        tooltip: '下一月',
                        onTap: () => provider.shiftMonthBy(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '本月结余',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11.5,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '¥ ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fmtMoney(summary.balance),
                            style: heroMoneyStyle(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        _HeroStat(
                          label: '收入',
                          sign: '+',
                          value: summary.income,
                        ),
                        Container(
                          width: 1,
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        _HeroStat(
                          label: '支出',
                          sign: '-',
                          value: summary.expense,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MonthArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String sign;
  final double value;

  const _HeroStat({
    required this.label,
    required this.sign,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$sign${fmtMoney(value)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final int count;

  const _SectionTitle({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
      child: Row(
        children: [
          Text(
            '流水明细',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            '$count 笔',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
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
    final categoryColor = AppCategoryColors.of(record.category);
    final amountColor = isIncome
        ? AppSemanticColors.income
        : AppSemanticColors.expense;

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.l),
          onLongPress: () => _longPressAssociation(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppCategoryColors.tintOf(record.category),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Icon(
                    kCategoryIcons[record.category] ??
                        Icons.receipt_long_outlined,
                    size: 21,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (record.note.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          record.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${isIncome ? '+' : '-'}${fmtMoney(record.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('tx-${record.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => provider.deleteTransaction(record.id!),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: card,
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

  Future<void> _longPressAssociation(BuildContext ctx) async {
    HapticFeedback.selectionClick();
    final metaList = await ArticleService.loadMeta();
    final match = ArticleService.findByCategory(metaList, record.category);
    if (!ctx.mounted) return;
    if (match == null) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text('「${record.category}」暂无关联知识')));
      return;
    }
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(meta: match)));
  }
}
