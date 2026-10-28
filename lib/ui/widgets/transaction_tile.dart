import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../models/transaction_record.dart';
import '../../providers/finance_provider.dart';
import '../../services/article_service.dart';
import '../../services/format.dart';
import '../app_tokens.dart';
import '../pages/article_detail_page.dart';

// ==================================================================
// 组件主体
// ==================================================================
/// 单条流水卡片：分类彩色图标 + 金额；左滑删除、长按关联知识
class TransactionTile extends StatelessWidget {
  final TransactionRecord record;

  const TransactionTile({super.key, required this.record});

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
