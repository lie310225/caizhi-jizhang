import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../providers/finance_provider.dart';

/// "记一笔"底部弹窗表单：类型 / 分类 / 金额 / 日期 / 备注
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  TxType _type = TxType.expense;
  String? _category;
  DateTime _date = DateTime.now();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<CategoryConfig> get _categories =>
      _type == TxType.expense ? kExpenseCategories : kIncomeCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final raw = _amountCtrl.text.trim();
    final valid = RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw);
    final amount = double.tryParse(raw);
    if (!valid || amount == null || amount <= 0) {
      _toast('请输入大于 0 的金额（最多两位小数）');
      return;
    }
    if (_category == null) {
      _toast('请选择分类');
      return;
    }
    await context.read<FinanceProvider>().addTransaction(
      type: _type,
      category: _category!,
      amount: double.parse(amount.toStringAsFixed(2)),
      date: DateFormat('yyyy-MM-dd').format(_date),
      note: _noteCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TxType>(
                segments: const [
                  ButtonSegment(
                    value: TxType.expense,
                    label: Text('支出'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: TxType.income,
                    label: Text('收入'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _category = null;
                }),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _category == c.name,
                      onSelected: (_) => setState(() => _category = c.name),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '金额',
                  prefixText: '¥ ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: '备注（选填）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_outlined),
                  const SizedBox(width: 8),
                  Text(DateFormat('yyyy年MM月dd日').format(_date)),
                  const Spacer(),
                  TextButton(onPressed: _pickDate, child: const Text('选择日期')),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ),
      ),
    );
  }
}
