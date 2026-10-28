import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../models/budget.dart';
import '../../providers/finance_provider.dart';
import '../../services/budgeting.dart';
import '../../services/format.dart';
import '../app_tokens.dart';

/// 预算管理：本月总预算 + 各支出分类预算，点击即可调整
class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final total = provider.monthBudgetStatus;
    final spent = provider.expenseCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('预算管理')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
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
          _TotalBudgetCard(
            status: total,
            onTap: () => _editBudget(
              context,
              category: Budget.totalCategory,
              title: '本月总预算',
              current: total?.limit,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Text(
                  '分类预算',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '点击分类即可设置',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final c in kExpenseCategories)
            _CategoryBudgetRow(
              category: c.name,
              spent: spent[c.name] ?? 0,
              limit: provider.budgetLimitOf(c.name),
              onTap: () => _editBudget(
                context,
                category: c.name,
                title: '「${c.name}」预算',
                current: provider.budgetLimitOf(c.name),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editBudget(
    BuildContext context, {
    required String category,
    required String title,
    double? current,
  }) async {
    final controller = TextEditingController(
      text: current == null ? '' : current.toStringAsFixed(2),
    );
    final provider = context.read<FinanceProvider>();

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            prefixText: '¥ ',
            hintText: '留空或填 0 表示不设预算',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, double.tryParse(v) ?? 0),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0.0),
              child: const Text('清除'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(controller.text.trim()) ?? 0,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await provider.setBudget(category: category, amount: amount);
  }
}

/// 总预算卡片：进度条 + 已用 / 剩余（超支转为琥珀色）
class _TotalBudgetCard extends StatelessWidget {
  final BudgetStatus? status;
  final VoidCallback onTap;

  const _TotalBudgetCard({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: s == null
                ? Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '还未设置本月总预算',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '设个额度，超支时会第一时间提醒你',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  )
                : _buildBody(context, s),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BudgetStatus s) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (s.ratio * 100).round();
    final accent = s.exceeded
        ? const Color(0xFFEF6C00)
        : AppSemanticColors.income;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '本月总预算',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              fmtMoney(s.limit),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              fmtMoney(s.used),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              s.exceeded ? '已超支 $percent%' : '已用 $percent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: s.fillRatio,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.exceeded
              ? '超出 ${fmtMoney(-s.remaining)}，建议看看哪类花超了'
              : '可用余额 ${fmtMoney(s.remaining)}',
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 单个分类的预算行
class _CategoryBudgetRow extends StatelessWidget {
  final String category;
  final double spent;
  final double? limit;
  final VoidCallback onTap;

  const _CategoryBudgetRow({
    required this.category,
    required this.spent,
    required this.limit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = limit;
    final exceeded = l != null && spent > l;
    final accent = exceeded
        ? const Color(0xFFEF6C00)
        : AppCategoryColors.of(category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.l),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppCategoryColors.tintOf(category),
                        borderRadius: BorderRadius.circular(AppRadius.s),
                      ),
                      child: Icon(
                        kCategoryIcons[category] ?? Icons.receipt_long_outlined,
                        size: 18,
                        color: AppCategoryColors.of(category),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      l == null
                          ? '已用 ${fmtMoney(spent)} · 未设'
                          : '${fmtMoney(spent)} / ${fmtMoney(l)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: l == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: l == null ? scheme.onSurfaceVariant : accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                  ],
                ),
                if (l != null && l > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (spent / l).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
