import 'package:flutter/material.dart';

// ==================================================================
// 类型定义
// ==================================================================
/// 空状态视觉密度
enum EmptyStateVariant { compact, spacious }

// ==================================================================
// 常量
// ==================================================================
/// 各页面的空状态配置（icon + title + subtitle + action）
final class EmptyStatePresets {
  static const txEmpty = EmptyStateConfig(
    icon: Icons.receipt_long_outlined,
    title: '还没有任何记录',
    subtitle: '点右下角 ＋ 开始记第一笔账',
  );

  static const balanceEmpty = EmptyStateConfig(
    icon: Icons.account_balance_wallet_outlined,
    title: '还没有资产负债条目',
    subtitle: '点击右上方 + 开始记录你的第一张卡吧',
  );

  static const noExportableData = EmptyStateConfig(
    icon: Icons.bar_chart_outlined,
    title: '没有可以导出的记录',
    subtitle: '先记一笔流水再来导出吧',
  );

  static const noReportData = EmptyStateConfig(
    icon: Icons.insights_outlined,
    title: '还没有数据可以生成报表',
    subtitle: '先记几笔流水，利润表和现金流量表才会有内容',
  );

  static const noExpenseData = EmptyStateConfig(
    icon: Icons.pie_chart_outline,
    title: '本月暂无支出记录',
    subtitle: '记一笔支出后，分类占比图才会出现',
  );

  static const noKnowledgeMatch = EmptyStateConfig(
    icon: Icons.auto_awesome_outlined,
    title: '这个分类下暂时没有知识',
    subtitle: '试试长按别的流水，也许会有惊喜',
  );
}

// ==================================================================
// 配置类
// ==================================================================
/// 空状态组件的配置
final class EmptyStateConfig {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateConfig({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
}

// ==================================================================
// 组件主体
// ==================================================================
/// 通用空状态组件：图标 + 标题 + 副标题 + 可选 CTA 按钮
class EmptyState extends StatelessWidget {
  final EmptyStateConfig config;
  final EmptyStateVariant variant;

  const EmptyState({
    super.key,
    required this.config,
    this.variant = EmptyStateVariant.spacious,
  });

  factory EmptyState.preset(
    EmptyStateConfig preset, {
    EmptyStateVariant variant = EmptyStateVariant.spacious,
  }) => EmptyState(config: preset, variant: variant);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spacer = variant == EmptyStateVariant.spacious
        ? const SizedBox(height: 12)
        : const SizedBox(height: 8);
    final iconSize = variant == EmptyStateVariant.spacious ? 56.0 : 40.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: iconSize, color: scheme.outlineVariant),
            spacer,
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (config.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                config.subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
            if (config.action != null) ...[
              const SizedBox(height: 16),
              config.action!,
            ],
          ],
        ),
      ),
    );
  }
}
