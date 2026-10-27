# 财智记账 Android APP — MVP 设计文档

- 日期：2026-10-27
- 状态：已与需求方逐节确认
- 关联：本仓库根目录的创意方案（index.html / README.md）

## 1. 背景与目标

"财智记账"已完成创意方案并发布 GitHub Pages。本阶段目标：把创意落地为**可安装的 Android APK**，核心卖点"三大报表个人化"必须在 v1 体现。

## 2. 范围

### MVP 包含

| 模块 | 说明 |
| ---- | ---- |
| 记一笔 | 支出/收入切换、金额（>0，两位小数）、预置分类（餐饮/交通/购物/居住/娱乐/医疗/工资/理财/借还款/其他）、日期、备注 |
| 流水 | 按月分组列表、月度收/支/结余汇总条、月份切换 |
| 利润表 | 本月/本年收入、支出、结余、储蓄率（结余/收入） |
| 现金流量表 | 交易三分法：经营性（日常收支）/ 投资性（买卖理财）/ 筹资性（借入偿还），按月呈现净额 |
| 资产负债表 | 手动维护资产条目（现金、存款、投资、房产、车辆）与负债条目（房贷、消费贷、其他借款），自动计算净资产 |
| 知识模块 | 仅预留入口（"我的"页占位），v2 迭代实现 |

### 非目标（v1 不做）

- 云同步、账号体系、多账本、多币种
- 记录编辑图片附件、周期自动记账
- 正式上架签名与应用商店分发

## 3. 技术选型

选 **Flutter**（已与备选方案对比确认）：

- 本机环境就绪：Flutter 3.41.4 stable / Dart 3.11.1 / OpenJDK 17 / Android SDK 36.1.0
- 一套代码、Material 3、fl_chart 图表生态成熟，`flutter build apk` 一条命令出包
- 备选：Kotlin 原生（周期长）、React Native/Expo（本机 Node 未配置且云构建需账号）——均被否决

### 依赖

- `sqflite`：本地 SQLite 存储
- `provider`：状态管理
- `fl_chart`：趋势折线图、分类环形图
- `intl`：日期与货币格式化

## 4. 架构与数据模型

### 页面结构（底部 4 Tab）

1. **记账**：流水首页（快捷"记一笔"按钮 + 流水列表 + 月汇总条）
2. **报表**：利润表 + 现金流量表 Tab 切换 + 收支趋势折线图、分类占比环形图
3. **资产负债**：资产负债表展示 + 资产/负债条目管理（增删）+ 净资产汇总
4. **我的**：设置占位 + 知识模块入口（v2）

### 数据模型（SQLite，纯本地）

```
transactions
  id INTEGER PK AUTOINCREMENT
  type TEXT          -- 'expense' | 'income'
  category TEXT      -- 预置分类名
  amount REAL        -- >0，两位小数
  flow_type TEXT     -- 'operating' | 'investing' | 'financing'（现金流三分法，按分类映射）
  date TEXT          -- 'yyyy-MM-dd'
  note TEXT          -- 可空
  created_at TEXT

balance_items
  id INTEGER PK AUTOINCREMENT
  kind TEXT          -- 'asset' | 'liability'
  name TEXT          -- 条目名（如"活期存款"）
  amount REAL
  updated_at TEXT
```

- 交易分类 → 现金流三分法映射：工资/餐饮/交通/购物/居住/娱乐/医疗/其他 → 经营性；理财 → 投资性；借还款 → 筹资性
- 利润表与现金流量表均由 transactions 实时聚合，不冗余存储

## 5. 界面与交互

- Material 3，绿色金融主题（与创意方案视觉一致），纯中文，移动端优先
- 金额输入自定义数字键盘体验（系统数字键盘即可），必填校验
- 空状态引导：无记录时展示"记下第一笔"引导页

## 6. 打包与交付

- 包名 `com.caizhi.finance`，minSdk 24（Android 7.0+），targetSdk 36
- v1 使用默认签名出 release APK（个人侧载可用）；正式签名/上架留待后续，避免 keystore 密码管理负担
- 交付物：`caizhi-app/build/app/outputs/flutter-apk/app-release.apk` 复制到工作目录，并上传 GitHub Release（可选）

## 7. 错误处理

- 金额必须 > 0 且最多两位小数；非法输入禁止提交
- 删除记录/资产负债条目二次确认
- 数据库操作失败提示轻量 SnackBar，不崩溃

## 8. 测试策略

- 报表聚合逻辑（三分法映射、月度汇总、净资产计算）写单元测试
- UI 由需求方人工验证（按用户规则，代码修改后不自动验证）

## 9. 里程碑

1. `flutter create caizhi-app`（工作目录下，与 finance-app-proposal 并列）
2. 数据层（模型 + sqflite + provider）
3. 记账/流水 UI
4. 三大报表页 + 图表
5. 打包 APK + 交付

## 10. 风险与对策

| 风险 | 对策 |
| ---- | ---- |
| maven.google.com 访问超时 | Gradle 仓库改用阿里云镜像 |
| pub.dev 拉包慢 | 设置 FLUTTER_STORAGE_BASE_URL / PUB_HOSTED_URL 国内镜像 |
| GitHub 推送不稳 | 已知用 `git -c http.version=HTTP/1.1` 可成功 |
