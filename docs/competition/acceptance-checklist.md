# MoonTrustFlow 验收清单

## 仓库要求

- [x] 使用独立仓库开发 MoonTrustFlow。
- [x] README.md 为普通文件，不使用 symlink。
- [x] 仓库包含许可证、源码、测试、CLI、CI 和文档。
- [x] GitLink 目标仓库为 `https://www.gitlink.org.cn/lllglllg/MoonTrustFlow`。
- [x] GitHub 目标仓库为 `https://github.com/lllg123/MoonTrustFlow-MoonBit-`。
- [x] 本地仓库提交数控制在 10-20 次有效提交范围内。

## 功能要求

- [x] 支持 `.mtf` 模型解析。
- [x] 支持 `source`、`sink`、`sanitizer`、`boundary`、`node`、`edge`。
- [x] 支持 `deny`、`require through=`、`allow` 三类策略。
- [x] 支持 `severity=` 风险等级。
- [x] 支持重复节点、未知指令、缺少箭头等语法诊断。
- [x] 支持按策略评估可达路径。
- [x] 支持例外路径精确压制。
- [x] 支持稳定文本报告输出。

## 验证命令

- [x] `moon info`
- [x] `moon fmt --check`
- [x] `moon test`
- [x] `moon run cmd/main`
- [x] `git ls-files -s README.md` 显示 `100644`
- [x] `git rev-list --count HEAD` 位于 10-20 之间
- [x] 旧项目和敏感 AI 痕迹关键词扫描无命中

## 后续扩展

- [ ] 支持从真实 `.mtf` 文件读取模型。
- [ ] 支持 JSON 或 HTML 报告。
- [ ] 支持策略分组和服务命名空间。
- [ ] 支持 MoonBit AST 或调用图适配器。
- [ ] 支持按环境切换不同 severity profile。
