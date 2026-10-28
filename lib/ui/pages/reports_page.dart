import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/article_service.dart';
import '../../services/format.dart';
import '../../services/statements.dart';
import '../app_tokens.dart';
import '../widgets/empty_state.dart';
import 'article_detail_page.dart';

/// 报表页：利润表 / 现金流量表 两个 Tab
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('报表'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '利润表'),
              Tab(text: '现金流量表'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_IncomeStatementView(), _CashFlowView()],
        ),
      ),
    );
  }
}

/// 月份切换行（报表页与首页共用 provider.selectedMonth）
class _MonthNav extends StatelessWidget {
  const _MonthNav();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => provider.shiftMonthBy(-1),
        ),
        Text(
          monthLabel(provider.selectedMonth),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => provider.shiftMonthBy(1),
        ),
      ],
    );
  }
}

class _IncomeStatementView extends StatelessWidget {
  const _IncomeStatementView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final month = provider.monthSummary;
    final year = provider.yearSummary;
    final trend = provider.trend;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _MonthNav(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '利润表（${monthLabel(month.period)}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _StatementRow(
                  label: '收入',
                  value: month.income,
                  color: scheme.primary,
                ),
                _StatementRow(
                  label: '支出',
                  value: month.expense,
                  color: scheme.error,
                ),
                _StatementRow(
                  label: '结余',
                  value: month.balance,
                  color: scheme.secondary,
                ),
                _StatementRow(
                  label: '储蓄率',
                  valueText: '${(month.savingsRate * 100).toStringAsFixed(1)}%',
                  color: scheme.primary,
                ),
                const Divider(height: 24),
                Text(
                  '本年累计',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _StatementRow(
                  label: '收入',
                  value: year.income,
                  color: scheme.primary,
                ),
                _StatementRow(
                  label: '支出',
                  value: year.expense,
                  color: scheme.error,
                ),
                _StatementRow(
                  label: '结余',
                  value: year.balance,
                  color: scheme.secondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '近 6 个月结余趋势',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: _minY(trend),
                      maxY: _maxY(trend),
                      gridData: const FlGridData(drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${trend[v.toInt()].period.substring(5)}月',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < trend.length; i++)
                              FlSpot(i.toDouble(), trend[i].balance),
                          ],
                          isCurved: true,
                          color: scheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: scheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _minY(List<PeriodSummary> trend) {
    final values = trend.map((e) => e.balance).toList();
    final m = values.reduce((a, b) => a < b ? a : b);
    return m < 0 ? m * 1.2 : 0;
  }

  double _maxY(List<PeriodSummary> trend) {
    final values = trend.map((e) => e.balance).toList();
    final m = values.reduce((a, b) => a > b ? a : b);
    return m > 0 ? m * 1.2 : 1;
  }
}

class _StatementRow extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueText;
  final Color color;
  final Widget? trailing;

  const _StatementRow({
    required this.label,
    this.value,
    this.valueText,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            valueText ?? fmtMoney(value ?? 0),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null) ...[trailing!],
        ],
      ),
    );
  }
}

class _CashFlowView extends StatelessWidget {
  const _CashFlowView();

  /// 支出分类环形图调色板（业务语义色，跟随 app_tokens 统一定义）
  static const List<Color> palette = AppSemanticColors.expensePalette;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final cash = provider.cashFlow;
    final byCategory = provider.expenseCategories;
    final total = byCategory.values.fold(0.0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _MonthNav(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '现金流量表（${monthLabel(provider.selectedMonth)}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _StatementRow(
                  label: '经营活动净额（日常收支）',
                  value: cash.operating,
                  color: cash.operating >= 0 ? scheme.primary : scheme.error,
                  trailing: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => _openFlowArticle(context, 'operating'),
                  ),
                ),
                _StatementRow(
                  label: '投资活动净额（买卖理财）',
                  value: cash.investing,
                  color: cash.investing >= 0 ? scheme.primary : scheme.error,
                  trailing: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => _openFlowArticle(context, 'investing'),
                  ),
                ),
                _StatementRow(
                  label: '筹资活动净额（借入偿还）',
                  value: cash.financing,
                  color: cash.financing >= 0 ? scheme.primary : scheme.error,
                  trailing: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => _openFlowArticle(context, 'financing'),
                  ),
                ),
                const Divider(height: 24),
                _StatementRow(
                  label: '现金净增加额',
                  value: cash.net,
                  color: scheme.secondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支出分类占比', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                if (total <= 0)
                  EmptyState.preset(
                    EmptyStatePresets.noExpenseData,
                    variant: EmptyStateVariant.compact,
                  )
                else ...[
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 48,
                        sectionsSpace: 2,
                        sections: [
                          for (var i = 0; i < byCategory.length; i++)
                            PieChartSectionData(
                              value: byCategory.values.elementAt(i),
                              title:
                                  '${(byCategory.values.elementAt(i) / total * 100).toStringAsFixed(0)}%',
                              radius: 60,
                              color: palette[i % palette.length],
                              titleStyle: TextStyle(
                                fontSize: 11,
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < byCategory.length; i++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              color: palette[i % palette.length],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${byCategory.keys.elementAt(i)} ${fmtMoney(byCategory.values.elementAt(i))}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFlowArticle(BuildContext ctx, String flow) async {
    final metaList = await ArticleService.loadMeta();
    final match = ArticleService.findByFlow(metaList, flow);
    if (!ctx.mounted) return;
    if (match == null) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('暂无该区块的入门文章')));
      return;
    }
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(meta: match)));
  }
}
