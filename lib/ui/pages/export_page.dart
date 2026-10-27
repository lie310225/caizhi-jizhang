import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/finance_provider.dart';
import '../../services/statements.dart';

enum _RangeOption { all, yearLast, yearThis, sixMonths, custom }

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  _RangeOption _range = _RangeOption.all;
  DateTimeRange? _customRange;
  bool _busy = false;

  String get _label {
    final now = DateTime.now();
    switch (_range) {
      case _RangeOption.all:
        return '全部记录';
      case _RangeOption.yearLast:
        return '${now.year - 1} 年';
      case _RangeOption.yearThis:
        return '${now.year} 年';
      case _RangeOption.sixMonths:
        return '近 6 个月';
      case _RangeOption.custom:
        if (_customRange == null) return '自定义（未选择）';
        final f = DateFormat('yyyy-MM-dd');
        return '${f.format(_customRange!.start)} ~ ${f.format(_customRange!.end)}';
    }
  }

  String? get _yearPrefix {
    final now = DateTime.now();
    switch (_range) {
      case _RangeOption.yearLast:
        return '${now.year - 1}';
      case _RangeOption.yearThis:
        return '${now.year}';
      default:
        return null;
    }
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _range = _RangeOption.custom;
      });
    }
  }

  Future<void> _doExport() async {
    final provider = context.read<FinanceProvider>();
    setState(() => _busy = true);
    try {
      String? monthPrefix;
      String? yearPrefix = _yearPrefix;
      if (_range == _RangeOption.sixMonths) {
        monthPrefix = shiftMonth(
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
            -5);
      }
      final path = await provider.exportCsvZip(
        monthPrefix: monthPrefix,
        yearPrefix: yearPrefix,
      );
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('导出完成')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final total = provider.records.length;
    final filtered = _computeFiltered(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('导出数据')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('时间范围',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                          label: const Text('全部'),
                          selected: _range == _RangeOption.all,
                          onSelected: (_) => setState(() => _range = _RangeOption.all)),
                      ChoiceChip(
                          label: const Text('去年'),
                          selected: _range == _RangeOption.yearLast,
                          onSelected: (_) => setState(() => _range = _RangeOption.yearLast)),
                      ChoiceChip(
                          label: const Text('今年'),
                          selected: _range == _RangeOption.yearThis,
                          onSelected: (_) => setState(() => _range = _RangeOption.yearThis)),
                      ChoiceChip(
                          label: const Text('近 6 个月'),
                          selected: _range == _RangeOption.sixMonths,
                          onSelected: (_) => setState(() => _range = _RangeOption.sixMonths)),
                      ChoiceChip(
                          label: Text(_range == _RangeOption.custom
                              ? '自定义 ✓'
                              : '自定义...'),
                          selected: _range == _RangeOption.custom,
                          onSelected: (_) => _pickCustom()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('当前选择：$_label',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    const Expanded(child: Text('transactions.csv（过滤后）')),
                    Text('$filtered 条'),
                  ]),
                  Row(children: [
                    const Expanded(child: Text('balance_items.csv（全量）')),
                    Text('${provider.balanceItems.length} 条'),
                  ]),
                  Row(children: [
                    const Expanded(child: Text('打包格式')),
                    Text('zip（UTF-8 BOM CSV）'),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
              onPressed: _busy ? null : _doExport,
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('导出并分享')),
          const SizedBox(height: 8),
          Text(
              _range == _RangeOption.all && total == 0
                  ? '⚠️ 没有交易记录，导出的 zip 只有空表头 CSV'
                  : '导出后将打开系统分享面板（微信/邮件/网盘/保存到手机）',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  int _computeFiltered(FinanceProvider p) {
    final year = _yearPrefix;
    if (_range == _RangeOption.all) return p.records.length;
    if (_range == _RangeOption.yearLast || _range == _RangeOption.yearThis) {
      return p.records.where((r) => r.date.startsWith(year!)).length;
    }
    if (_range == _RangeOption.sixMonths) {
      final start = shiftMonth(
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
          -5);
      return p.records.where((r) => r.date.compareTo('$start-01') >= 0).length;
    }
    if (_range == _RangeOption.custom && _customRange != null) {
      final f = DateFormat('yyyy-MM-dd');
      final s = f.format(_customRange!.start);
      final e = f.format(_customRange!.end);
      return p.records
          .where((r) => r.date.compareTo(s) >= 0 && r.date.compareTo(e) <= 0)
          .length;
    }
    return 0;
  }
}
