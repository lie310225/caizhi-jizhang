import 'package:flutter/material.dart';

/// 我的：知识模块 v2 占位
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('财务知识课堂'),
            subtitle: Text('场景化财务知识学习（v2 即将上线）'),
            trailing: Icon(Icons.chevron_right),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
