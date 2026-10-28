import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/budgeting.dart';
import '../../services/format.dart';
import '../app_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';
import 'budget_page.dart';
import 'transaction_search_page.dart';

/// 流水首页：渐变主卡（月份 + 结余 + 收支 + 预算进度）+ 按日分组流水 + 记一笔
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
        children.add(TransactionTile(record: r));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('财智记账'),
        actions: [
          IconButton(
            tooltip: '搜索流水',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransactionSearchPage()),
            ),
          ),
        ],
      ),
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
// 渐变主卡：视觉焦点，大数字 + 收支对照 + 预算进度
// ------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final summary = provider.monthSummary;
    final budget = provider.monthBudgetStatus;

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
                  if (budget != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _BudgetMeter(status: budget),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 主卡内的预算进度条：未超支为白色，超支转为琥珀色
class _BudgetMeter extends StatelessWidget {
  final BudgetStatus status;

  const _BudgetMeter({required this.status});

  @override
  Widget build(BuildContext context) {
    final percent = (status.ratio * 100).round();
    final exceeded = status.exceeded;
    final fill = exceeded
        ? const Color(0xFFFFB74D)
        : Colors.white.withValues(alpha: 0.88);
    final hint = exceeded
        ? '已超支 $percent% · 超出 ${fmtMoney(-status.remaining)}'
        : '剩余 ${fmtMoney(status.remaining)}';

    return InkResponse(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BudgetPage())),
      radius: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '本月预算',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                fmtMoney(status.limit),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                exceeded ? '已超支 $percent%' : '已用 $percent%',
                style: TextStyle(
                  color: exceeded ? fill : Colors.white.withValues(alpha: 0.8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: status.fillRatio,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(fill),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                hint,
                style: TextStyle(
                  color: exceeded ? fill : Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                '管理 ›',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
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
