# MoonTrustFlow 验收清单

更新时间：2026-08-14

本清单对应 2026-08-14 再次核对后的 OSC2026 官方源码、两个远程仓库与当前工程状态。
重点不再沿用早期“10-20 次提交”这样的旧口径，而是围绕公开开发、工程质量、
可运行性、可维护性和 MoonBit 生态贡献进行自查。

## 公开要求对照

- [x] 仓库公开可访问。
- [x] 项目以 MoonBit 为主要实现语言。
- [x] README 能说明定位、能力边界、使用方式、验证方式和限制说明。
- [x] 仓库包含源码、测试、fixture corpus、CI、设计文档和验收材料。
- [x] `LICENSE`、`NOTICE` 和 `CONTRIBUTING.md` 明确许可证、归属和可复现贡献流程。
- [x] GitLink 仓库为 `https://www.gitlink.org.cn/lllglllg/MoonTrustFlow`。
- [x] GitHub 仓库为 `https://github.com/lllg123/MoonTrustFlow-MoonBit`。
- [x] Mooncakes 发布命名空间统一为当前 GitHub/Mooncakes 账号 `lllg123/moontrustflow`，并能通过公开 API 查询。
- [x] 当前赛程与提交安排以官方 OSC2026 页面及组委会最新通知为准；本清单不固化可能过期的日期快照。

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
- [x] `scripts/verify_fixture_corpus.py` 对 9 个代表性模型执行 CLI 并校验期望摘要。
- [x] CLI 支持文本、JSON、SARIF、图摘要、风险评估和部署契约检查模式。
- [x] 生产 MoonBit 源码规模为 `3048` 行（排除测试与生成接口），并由质量门禁、基线比较和批量分析 API 支撑真实应用流程。

## 本地验证命令

- [x] `moon check --target all --deny-warn`
- [x] `moon test --deny-warn`（无 C 编译器时跳过 native）
- [x] `python scripts\verify_fixture_corpus.py`
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
- [x] 当前仓库补充了 web service、message pipeline、断开路径、转义/注释和空模型基准。
- [x] 当前仓库补充了 `CHANGELOG.md`、来源说明和自查脚本。
- [x] 当前生产 `.mbt` 代码规模为 `3048` 行；测试 `.mbt` 规模为 `449` 行。
- [x] 公开提交历史、双远程和 Mooncakes 发布状态可核查。

## 远端完成标准

- [x] GitLink 与 GitHub 的发布内容、验收材料和功能版本一致；两个平台因独立镜像提交可拥有不同 commit ID，已分别核验远程 HEAD。
- [x] GitHub Actions 三平台矩阵已补齐；源码与 fixture corpus 均在 CI 中验证。
- [x] GitLink / GitHub 首页标题、简介、README 首屏与仓库文档一致。
- [x] GitLink 与 GitHub 当前贡献者 API 均未发现 `python123` 或其他异常贡献者。
- [x] 默认分支状态与验收材料一致：GitHub 为 `main`，GitLink 为 `master`。

## 受限项说明

- [x] 不通过重写历史处理旧作者身份。
- [x] 不伪造本机 native 测试已通过的结论。
- [x] 若 GitLink “虚拟贡献者”来自平台统计，则记录来源，不通过改写历史处理。
