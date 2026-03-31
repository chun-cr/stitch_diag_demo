# stitch_diag_demo

用于制作项目 UI。

## 项目内国际化 Skill

本项目已内置一个项目级 skill，用于约束后续 Flutter 页面开发时自动完成国际化接入，而不是留下硬编码文案。

### 路径

```txt
.opencode/skills/flutter-page-i18n-guard/SKILL.md
```

### 适用场景

当后续模型执行以下任务时，应优先使用这个 skill：

- 新增 Flutter 页面
- 修改页面文案
- 新增按钮、卡片、菜单、标签、提示、表单、弹窗
- 调整 `home / profile / scan / report` 页面内容
- 新增语言
- 调整语言切换逻辑
- 做多语言 UI 巡检

### 这个 skill 当前覆盖的能力

它已经合并为一个总 skill，包含 4 个模式：

1. **页面开发自动国际化**
   - 新增或修改用户可见文案时，自动接入 `gen-l10n`
   - 强制把新文案写入 ARB，而不是留在页面代码中

2. **多语言 UI 巡检**
   - 检查 `zh / en / ja / ko` 下的长度风险
   - 对紧凑布局补 `maxLines / overflow / Flexible / Expanded`

3. **新语言接入**
   - 新增 `app_xx.arb`
   - 接入 `supportedLocales`
   - 接入语言切换入口

4. **验证与测试**
   - `flutter gen-l10n`
   - `flutter analyze`
   - 必要时运行 app
   - 必要时更新最小本地化测试基线

### 本项目当前国际化状态

当前已支持：

- 中文（zh）
- 英文（en）
- 日文（ja）
- 韩文（ko）

并且已经具备：

- 语言切换入口（Profile 页面）
- locale 持久化
- 多语言 UI 高风险区域修正
- 最小测试基线恢复

### 后续开发要求

后续如果修改页面内容，默认遵守以下规则：

1. 用户可见文案不得直接硬编码在页面中
2. 新 key 必须同时补齐：
   - `lib/l10n/app_zh.arb`
   - `lib/l10n/app_en.arb`
   - `lib/l10n/app_ja.arb`
   - `lib/l10n/app_ko.arb`
3. 动态文案必须使用 ARB placeholder，不允许字符串拼接
4. 业务逻辑不得依赖翻译后的显示文案
5. 涉及紧凑布局必须检查多语言长度风险
6. 完成前至少执行：
   - `flutter gen-l10n`
   - `flutter analyze`

### 推荐使用方式

如果后续让模型继续开发页面，建议在需求里明确提一句：

```txt
请使用项目内 skill：flutter-page-i18n-guard
```

如果任务涉及：

- 页面改版
- 文案新增
- 新语言接入
- 多语言 UI 修复

则默认都应触发这个 skill。
