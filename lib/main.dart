import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'ui/root_tabs.dart';
import 'ui/theme.dart';

void main() {
  runApp(const CaizhiApp());
}

class CaizhiApp extends StatelessWidget {
  const CaizhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..load(),
      child: MaterialApp(
        title: '财智记账',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RootTabs(),
      ),
    );
  }
}
