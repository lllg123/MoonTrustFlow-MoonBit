# MoonTrustFlow 验收清单

更新时间：2026-07-10

本清单对应 2026-07-10 再次核对后的 OSC2026 公开页面与当前仓库实际状态。
重点不再沿用早期“10-20 次提交”这样的旧口径，而是围绕公开开发、工程质量、
可运行性、可维护性和 MoonBit 生态贡献进行自查。

## 公开要求对照

- [x] 仓库公开可访问。
- [x] 项目以 MoonBit 为主要实现语言。
- [x] README 能说明定位、能力边界、使用方式、验证方式和限制说明。
- [x] 仓库包含源码、测试、fixture、CI、设计文档和验收材料。
- [x] GitLink 仓库为 `https://www.gitlink.org.cn/lllglllg/MoonTrustFlow`。
- [x] GitHub 仓库为 `https://github.com/lllg123/MoonTrustFlow-MoonBit`。
- [x] Mooncakes 已发布并能通过公开 API 查询到 `llgllg/moontrustflow`。
- [x] 当前公开赛程已按 `2026-07-13` 至 `2026-07-17` 的验收窗口更新到文档口径。

## 当前实现能力

- [x] 支持 `.mtf` 模型解析。
- [x] 支持 `source`、`sink`、`sanitizer`、`boundary`、`node`、`edge`。
- [x] 支持 `deny`、`require through=`、`allow` 三类策略。
- [x] 支持 `severity=high|medium|low` 风险等级。
- [x] 支持重复节点、未知指令、缺少箭头、未闭合引号等诊断。
- [x] 支持多路径、分支汇合与循环剪枝后的可达路径评估。
- [x] 支持精确路径例外抑制。
- [x] 支持稳定文本报告和 JSON 报告。
- [x] 支持通过 `scripts/analyze_model.ps1` 对真实 `.mtf` 文件做仓库内 CLI 分析。

## 本地验证命令

- [x] `moon check --target all`
- [x] `moon test`
- [x] `moon fmt` 后 `git diff --exit-code`
- [x] `moon info` 后 `git diff --exit-code`
- [x] `moon run cmd/main`
- [x] `powershell -ExecutionPolicy Bypass -File scripts\analyze_model.ps1 -Path fixtures\models\webapp_taint.mtf -Json`
- [x] `git ls-files -s README.md` 显示普通跟踪文件模式 `100644`

说明：

- 本机缺少系统 C 编译器，因此 `moon test --target all` 的 native 部分不能作为
  本地硬门槛伪装通过。
- 对 native 目标的完整覆盖由 GitHub Actions 提供，并在 CI 中显式执行
  `moon test --target all`。

## 规模与公开开发痕迹

- [x] 当前仓库已拆分为多文件核心实现，而非单文件演示。
- [x] 当前仓库补充了复杂污染传播 fixture 与边界测试。
- [x] 当前仓库补充了 `CHANGELOG.md`、来源说明和自查脚本。
- [x] 当前跟踪的 `.mbt` / `.mbti` 代码规模已提升到约 `1026` 行。
- [x] 公开提交历史、双远程和 Mooncakes 发布状态可核查。

## 远端完成标准

- [ ] GitLink 与 GitHub 指向同一最新提交。
- [ ] GitHub Actions 三平台矩阵完成并通过。
- [ ] GitLink / GitHub 首页标题、简介、README 首屏与仓库文档一致。
- [ ] GitLink “虚拟贡献者”问题已确认来源并在当前约束下处理完毕或记录为受限项。
- [ ] 默认分支状态与验收材料一致，并记录 GitLink / GitHub 各自真实默认分支。

## 受限项说明

- [x] 不通过重写历史处理旧作者身份。
- [x] 不伪造本机 native 测试已通过的结论。
- [x] 若 GitLink “虚拟贡献者”来自平台统计，则记录来源，不通过改写历史处理。
