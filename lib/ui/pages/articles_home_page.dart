import 'package:flutter/material.dart';
import '../../services/article_meta.dart';
import '../../services/article_service.dart';
import 'article_detail_page.dart';

class ArticlesHomePage extends StatefulWidget {
  const ArticlesHomePage({super.key});

  @override
  State<ArticlesHomePage> createState() => _ArticlesHomePageState();
}

class _ArticlesHomePageState extends State<ArticlesHomePage> {
  List<ArticleMeta> _meta = const [];
  String? _error;

  static const _categoryTitles = {
    'daily': '日常记账背后',
    'investing': '理财与投资',
    'debt': '借贷与债务',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await ArticleService.loadMeta();
      if (mounted) setState(() => _meta = m);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = ArticleService.groupByCategory(_meta);

    return Scaffold(
      appBar: AppBar(title: const Text('财务知识课堂')),
      body: _error != null
          ? Center(child: Text('知识内容加载失败，请检查应用版本\n$_error'))
          : _meta.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '用中学、学中用 —— 每记一笔账，都能学一点财务知识',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final cat in ['daily', 'investing', 'debt']) ...[
                  _CategoryCard(
                    title: _categoryTitles[cat] ?? cat,
                    count: groups[cat]?.length ?? 0,
                    articles: groups[cat] ?? const [],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final List<ArticleMeta> articles;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$count 篇',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...articles.map(
              (a) => ListTile(
                dense: true,
                title: Text(a.title),
                subtitle: Text(
                  '${a.summary} · 约 ${a.readMinutes} 分钟',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArticleDetailPage(meta: a)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
