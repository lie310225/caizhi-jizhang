import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../providers/finance_provider.dart';

/// 新建周期账单底部弹窗：名称 / 类型 / 分类 / 金额 / 每月日号
Future<void> showAddRecurringSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddRecurringSheet(),
  );
}

class _AddRecurringSheet extends StatefulWidget {
  const _AddRecurringSheet();

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  TxType _type = TxType.expense;
  String? _category;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _dayCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  List<CategoryConfig> get _categories =>
      _type == TxType.expense ? kExpenseCategories : kIncomeCategories;

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final raw = _amountCtrl.text.trim();
    final amount = double.tryParse(raw);
    final day = int.tryParse(_dayCtrl.text.trim());

    if (title.isEmpty) {
      _toast('请填写账单名称，如「房租」');
      return;
    }
    if (_category == null) {
      _toast('请选择分类');
      return;
    }
    if (amount == null || amount <= 0) {
      _toast('请输入大于 0 的金额');
      return;
    }
    if (day == null || day < 1 || day > 28) {
      _toast('每月日期请填 1-28');
      return;
    }

    await context.read<FinanceProvider>().addRecurring(
      title: title,
      category: _category!,
      type: _type,
      amount: double.parse(amount.toStringAsFixed(2)),
      dayOfMonth: day,
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
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: '账单名称',
                  hintText: '如：房租、房贷、视频会员',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '每月金额',
                        prefixText: '¥ ',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: scheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _dayCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        labelText: '每月日',
                        suffixText: '号',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '日期固定填 1-28，避免小月没有 29-31 日的问题',
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('保存账单')),
            ],
          ),
        ),
      ),
    );
  }
}
