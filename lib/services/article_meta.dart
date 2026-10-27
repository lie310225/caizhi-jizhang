/// 财务知识文章元数据
class ArticleMeta {
  final String id;
  final String title;
  final String category; // daily / investing / debt
  final List<String> relatedCategories; // 记账分类中文名
  final List<String> relatedFlows; // operating / investing / financing
  final String summary;
  final int readMinutes;
  final String file; // asset 相对路径，如 daily/d01_eating.md

  const ArticleMeta({
    required this.id,
    required this.title,
    required this.category,
    required this.relatedCategories,
    required this.relatedFlows,
    required this.summary,
    required this.readMinutes,
    required this.file,
  });

  factory ArticleMeta.fromMap(Map<String, dynamic> m) => ArticleMeta(
    id: m['id'] as String,
    title: m['title'] as String,
    category: m['category'] as String,
    relatedCategories: (m['relatedCategories'] as List<dynamic>).cast<String>(),
    relatedFlows: (m['relatedFlows'] as List<dynamic>).cast<String>(),
    summary: m['summary'] as String,
    readMinutes: (m['readMinutes'] as num).toInt(),
    file: m['file'] as String,
  );
}
