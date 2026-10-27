import 'dart:convert';
import 'package:flutter/services.dart';
import 'article_meta.dart';

/// 纯静态：加载 asset 里的知识文章元数据与内容
class ArticleService {
  /// 生产环境默认：从 Flutter asset 读取
  static Future<List<ArticleMeta>> loadMeta() async {
    final raw = await rootBundle.loadString('assets/articles/meta.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => ArticleMeta.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// 生产环境默认：从 Flutter asset 读取 Markdown 正文
  static Future<String> loadContent(String file) async =>
      rootBundle.loadString('assets/articles/$file');

  /// 可注入读取器（测试用）：路径 + 读取器函数，返回 Future 字符串
  static Future<String> loadAssetFile(
    String path, {
    required Future<String> Function(String) rootBundleGetter,
  }) => rootBundleGetter(path);

  /// 按记账分类匹配第一篇文章（按 meta.json 数组顺序）
  static ArticleMeta? findByCategory(List<ArticleMeta> meta, String category) {
    for (final m in meta) {
      if (m.relatedCategories.contains(category)) return m;
    }
    return null;
  }

  /// 按现金流三分法匹配入门文章（取每个分类的第一篇）
  static ArticleMeta? findByFlow(List<ArticleMeta> meta, String flow) {
    for (final m in meta) {
      if (m.relatedFlows.contains(flow)) return m;
    }
    return null;
  }

  /// 按 category 分组（首页用）
  static Map<String, List<ArticleMeta>> groupByCategory(List<ArticleMeta> meta) {
    final groups = <String, List<ArticleMeta>>{};
    for (final m in meta) {
      groups.putIfAbsent(m.category, () => []).add(m);
    }
    return groups;
  }
}
