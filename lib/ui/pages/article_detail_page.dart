import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../services/article_meta.dart';
import '../../services/article_service.dart';

/// 单篇文章详情
class ArticleDetailPage extends StatefulWidget {
  final ArticleMeta meta;
  const ArticleDetailPage({super.key, required this.meta});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await ArticleService.loadContent(widget.meta.file);
      if (mounted) setState(() => _content = text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.meta.title)),
      body: _content == null
          ? Center(child: _error != null
              ? Text('加载失败：$_error')
              : const CircularProgressIndicator())
          : MarkdownWidget(data: _content!),
    );
  }
}
