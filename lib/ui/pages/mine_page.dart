import 'package:flutter/material.dart';
import 'articles_home_page.dart';
import 'budget_page.dart';
import 'export_page.dart';

/// 我的：知识课堂 / 预算管理 / 导出数据
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('预算管理'),
            subtitle: const Text('本月总预算与分类预算'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BudgetPage())),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('财务知识课堂'),
            subtitle: const Text('场景化财务知识学习'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ArticlesHomePage())),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('导出数据'),
            subtitle: const Text('CSV 格式，系统分享'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ExportPage())),
          ),
          const Divider(height: 8),
          const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('设置'),
            subtitle: Text('v2 基础功能已上线'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
