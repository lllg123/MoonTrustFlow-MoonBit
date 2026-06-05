# MoonTrustFlow 验收清单

## 仓库要求

- [x] 使用独立仓库，不复用旧项目仓库。
- [x] README.md 是普通文件，不使用 symlink。
- [x] 仓库包含许可证、源码、测试、CLI 和文档。
- [ ] GitLink 仓库创建为 `python123/moontrustflow`。
- [ ] GitLink 仓库包含 10 次以上有效提交。

## 功能要求

- [x] 支持 `.mtf` 模型解析。
- [x] 支持 source、sink、sanitizer、node、edge、allow。
- [x] 支持重复节点和语法错误诊断。
- [x] 支持 source 到 sink 的污染传播检测。
- [x] 支持 sanitizer 截断传播。
- [x] 支持 allow 规则压制精确路径。
- [x] 支持多条风险路径报告。
- [x] 支持稳定文本报告输出。

## 验证命令

- [x] `moon test`
- [x] `moon run cmd/main`
- [ ] `moon info`
- [ ] `moon fmt --check`
- [ ] `rg -i "mooncsv|moonloglens|csv_parser|csv"` 无旧项目残留。
- [ ] `git ls-files -s README.md` 显示 `100644`。

## 后续扩展

- [ ] 支持从真实 `.mtf` 文件读取模型。
- [ ] 支持风险等级配置。
- [ ] 支持规则分组和命名空间。
- [ ] 支持 MoonBit AST 或调用图导入。
- [ ] 支持 HTML 或 JSON 报告。
