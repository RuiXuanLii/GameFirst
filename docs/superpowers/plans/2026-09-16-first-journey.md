# 首段江湖求学旅程 Implementation Plan

> **For agentic workers:** Execute tasks in this session using superpowers:executing-plans. Steps use checkbox syntax for tracking.

**Goal:** 大地图旅行、两派求学、阴阳心法修炼、性格试招、存档构成可玩闭环。
**Architecture:** 数据表描述地界与传承；独立 JourneyState 负责规则；界面只调用规则并呈现结果，绘图组件呈现地图，独立 3D 舞台呈现回合出招。
**Tech Stack:** Godot 4.7.2 / typed GDScript / Compatibility renderer.
**Spec:** docs/superpowers/specs/2026-09-16-wuxia-world-framework.md

## Global Constraints
- 内力、招数、性格状态构成核心；根骨、悟性、魅力不随日常操作增加。
- 系统能力不实现；按用户追加要求，2D 日程以天推进，战斗进入 3D 小场景。本节点采用回合切磋验证，实时弹反/QTE 尚未实现。
- 地名、门派名、数值是可替换原型内容。
- 保存前校验、版本化存档；读取失败保留现状与原文件。

## Tasks
- [x] 1. 规则与测试：创建 world_data.gd、journey_state.gd、tests/test_journey.gd。先验证缺少规则实现的失败，再实现 travel(destination)、learn()、cultivate()、equip(skill_id)、practice(provoked)、snapshot()/restore(data)。断言远程求学受限、相邻旅行、重复学习不复制、初始资质不变、状态短暂、损坏存档不污染状态。
- [x] 2. 世界界面：创建 scenes/journey.tscn、ui/journey_ui.gd、ui/world_canvas.gd、ui/theme_factory.gd。地图显示位置与路径，侧栏显示地点、行动与人物资质，武学谱可切换所学。招式演出显示阴阳差异与激愤原因。
- [x] 3. 持久化：创建 features/save_store.gd，用 user:// 独立命名文件保存，通过临时文件替换；加载完整校验后才更新人物。提供新旅程确认、手动存读档。
- [x] 4. 整体验证：规则测试、真实界面按钮流程、两种分辨率布局检查、Godot 全项目加载与运行、渲染截图；更新 README/进度并提交推送。

## 追加范围
- [x] BattleState 区分日程与战斗回合，处理内力、攻守、临时性格、胜负和重置。
- [x] BattleStage 在 SubViewport 中生成小型 3D 练武场、角色与出招镜头。
- [x] 渲染 UI 测试覆盖完整 6 回合切磋和地图返回。

## Verification commands
```powershell
& 'D:/Godot_v4.7.2-stable_win64_console.exe' --headless --path D:/lets-go --script res://tests/test_journey.gd
& 'D:/Godot_v4.7.2-stable_win64_console.exe' --headless --path D:/lets-go --script res://tests/test_ui.gd
```

关键验收：从临江镇经渡口拜访青岚，再经临江镇和赤岭进入震岳；学会阴阳两派传承；修炼不改变资质；练武场状态不泄漏到下一次；保存重载保持旅程。
