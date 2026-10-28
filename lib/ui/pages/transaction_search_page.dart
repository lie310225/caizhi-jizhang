import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';
import '../../services/tx_filter.dart';
import '../app_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';

/// 流水搜索：关键词 + 时间范围 + 收支类型 + 分类多选 + 排序
class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  TxFilter _filter = const TxFilter();

  /// 分类筛选项：支出在前、收入在后，去重保留首次出现
  static final List<String> _categoryOptions = () {
    final names = <String>[];
    for (final c in [...kExpenseCategories, ...kIncomeCategories]) {
      if (!names.contains(c.name)) names.add(c.name);
    }
    return names;
  }();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final results = filterTransactions(
      provider.records,
      _filter,
      anchorMonth: provider.selectedMonth,
    );
    final totals = filteredTotals(results);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: '搜索分类或备注',
            hintStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
            suffixIcon: _queryController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _queryController.clear();
                      setState(() => _filter = _filter.copyWith(query: ''));
                    },
                  ),
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          onChanged: (v) =>
              setState(() => _filter = _filter.copyWith(query: v)),
        ),
        actions: [
          IconButton(
            tooltip: _filter.sort == TxSort.dateDesc ? '按金额排序' : '按日期排序',
            icon: Icon(
              _filter.sort == TxSort.dateDesc
                  ? Icons.sort_outlined
                  : Icons.attach_money,
            ),
            onPressed: () => setState(
              () => _filter = _filter.copyWith(
                sort: _filter.sort == TxSort.dateDesc
                    ? TxSort.amountDesc
                    : TxSort.dateDesc,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in TxTimeRange.values)
                  _RangeChip(
                    label: r.label,
                    selected: _filter.range == r,
                    onSelected: (_) =>
                        setState(() => _filter = _filter.copyWith(range: r)),
                  ),
                const SizedBox(width: 4),
                for (final t in _typeOptions)
                  _RangeChip(
                    label: t.label,
                    selected: _filter.type == t.type,
                    onSelected: (_) => setState(
                      () => _filter = t.type == null
                          ? _filter.copyWith(clearType: true)
                          : _filter.copyWith(type: t.type),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              itemCount: _categoryOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final name = _categoryOptions[i];
                final selected = _filter.categories.contains(name);
                return _RangeChip(
                  label: name,
                  selected: selected,
                  accent: AppCategoryColors.of(name),
                  onSelected: (_) => setState(() {
                    final next = Set<String>.from(_filter.categories);
                    if (selected) {
                      next.remove(name);
                    } else {
                      next.add(name);
                    }
                    _filter = _filter.copyWith(categories: next);
                  }),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: Row(
              children: [
                Text(
                  '共 ${results.length} 笔',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '支出 ${fmtMoney(totals.expense)} · 收入 ${fmtMoney(totals.income)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: EmptyState.preset(
                      const EmptyStateConfig(
                        icon: Icons.search_off_outlined,
                        title: '没有符合条件的流水',
                        subtitle: '换个关键词，或放宽筛选条件试试',
                      ),
                      variant: EmptyStateVariant.compact,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: results.length,
                    itemBuilder: (_, i) => TransactionTile(record: results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  /// 收支类型选项：全部 / 支出 / 收入
  static const List<({String label, TxType? type})> _typeOptions = [
    (label: '全部类型', type: null),
    (label: '支出', type: TxType.expense),
    (label: '收入', type: TxType.income),
  ];
}

/// 统一圆角的筛选 chip
class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? accent;
  final ValueChanged<bool> onSelected;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? color : scheme.onSurfaceVariant,
      ),
      backgroundColor: Colors.white,
      selectedColor: color.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected
            ? color.withValues(alpha: 0.45)
            : scheme.outlineVariant.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
