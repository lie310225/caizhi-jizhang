import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance/services/article_service.dart';
import 'package:finance/services/article_meta.dart';

Future<List<ArticleMeta>> _loadTestMeta() async {
  final file = File('test/resource/articles/meta.json');
  final raw = await file.readAsString();
  final list = jsonDecode(raw) as List;
  return list.map((e) => ArticleMeta.fromMap(e as Map<String, dynamic>)).toList();
}

void main() {
  late List<ArticleMeta> metaList;

  setUpAll(() async {
    metaList = await _loadTestMeta();
  });

  test('ArticleMeta.fromMap 解析正确', () {
    final first = metaList.first;
    expect(first.id, 'd01');
    expect(first.title, '测试文章');
    expect(first.relatedCategories, ['餐饮']);
    expect(first.relatedFlows, ['operating']);
  });

  test('findByCategory 命中首条', () {
    // "还贷还借款" 匹配 i01 和 f01，按 meta.json 顺序应取 i01
    expect(ArticleService.findByCategory(metaList, '还贷还借款')?.id, 'i01');
  });

  test('findByCategory 无匹配返回 null', () {
    expect(ArticleService.findByCategory(metaList, '娱乐'), isNull);
  });

  test('findByFlow 命中', () {
    expect(ArticleService.findByFlow(metaList, 'operating')?.id, 'd01');
    expect(ArticleService.findByFlow(metaList, 'financing')?.id, 'f01');
  });

  test('groupByCategory 正确分组', () {
    final groups = ArticleService.groupByCategory(metaList);
    expect(groups['daily']?.length, 1);
    expect(groups['investing']?.length, 1);
    expect(groups['debt']?.length, 1);
  });

  test('loadContent 读取文件', () async {
    final content = await ArticleService.loadAssetFile(
        'test/resource/articles/d01_test.md',
        rootBundleGetter: (path) => File(path).readAsString());
    expect(content, contains('测试'));
  });
}
