# MoonTrustFlow 验收清单

更新时间：2026-07-06

本清单用于对照组委会当前公开页面可见的验收重点，不再沿用早期本地草稿里
“10-20 次提交”这一旧说法。当前公开规则更关注项目是否真实可用、文档是否
清晰、测试和 CI 是否可运行，以及是否已发布到 `mooncakes.io`。

## 公开要求对照

- [x] 仓库公开可访问。
- [x] 项目以 MoonBit 为主要实现语言。
- [x] README 能说明定位、能力边界、使用方式和验证方式。
- [x] 仓库包含源码、测试、CLI 示例、CI 和设计文档。
- [x] GitLink 仓库为 `https://www.gitlink.org.cn/lllglllg/MoonTrustFlow`。
- [x] GitHub 仓库为 `https://github.com/lllg123/MoonTrustFlow-MoonBit`。
- [x] Mooncakes 已发布并能通过公开 API 查询到 `llgllg/moontrustflow`。

## 已实现能力

- [x] 支持 `.mtf` 模型解析。
- [x] 支持 `source`、`sink`、`sanitizer`、`boundary`、`node`、`edge`。
- [x] 支持 `deny`、`require through=`、`allow` 三类策略。
- [x] 支持 `severity=high|medium|low` 风险等级。
- [x] 支持重复节点、未知指令、缺少箭头等语法诊断。
- [x] 支持按策略评估可达路径。
- [x] 支持精确路径例外抑制。
- [x] 支持稳定的文本报告输出。

## 本地验证命令

- [x] `moon info`
- [x] `moon fmt --check`
- [x] `moon test`
- [x] `moon run cmd/main`
- [x] `git ls-files -s README.md` 显示普通跟踪文件模式 `100644`
- [x] 仓库中已清理旧 GitHub 尾部 `-` 链接
- [x] 仓库中未保留旧账号相关的可变文案痕迹

## 远端完成标准

- [x] GitLink 与 GitHub 指向同一最新提交。
- [x] GitHub Actions 最近一轮对 `main` / `master` 均通过。
- [ ] GitLink / GitHub 首页标题、简介、README 首屏与仓库文档一致。
- [ ] GitLink “虚拟贡献者”问题已确认来源并在当前约束下处理完毕或记录为受限项。

## 后续扩展方向

- [ ] 支持从真实 `.mtf` 文件读取模型。
- [ ] 支持 JSON 或 HTML 报告。
- [ ] 支持策略分组和服务命名空间。
- [ ] 支持 MoonBit AST 或调用图适配器。
- [ ] 支持按环境切换不同 severity profile。
