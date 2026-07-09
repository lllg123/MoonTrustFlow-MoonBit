# MoonTrustFlow 结项说明

更新时间：2026-07-10

## 1. 本轮整改目标

根据组委会预验收意见，本轮整改聚焦三件事：

1. 把仓库验证口径、CI 和文档同步到 MoonBit 0.10.3 兼容命令集。
2. 把项目从“单文件规则解析 demo”推进到“更像可接入真实工程的数据流治理库”。
3. 在不改写历史的前提下，补齐双远程、自查脚本和身份说明材料。

## 2. 已完成的核心改进

### 2.1 MoonBit 实现结构

- 将核心实现拆分为类型、解析、路径搜索、策略评估、报告格式化等多个 `.mbt` 文件。
- 保持公开 API 稳定，同时新增 JSON 报告能力。
- 保持核心分析包跨目标友好，不把 native-only 文件系统依赖直接压进库本体。

### 2.2 规则与测试覆盖

- 新增多源/多汇、链式 sanitizer、路径例外、循环剪枝、分支汇合等复杂 fixture。
- 扩充黑盒与白盒测试，补齐复杂污染传播与边界诊断场景。
- 当前本地 `moon test` 已通过，`moon check --target all` 已通过。

### 2.3 真实 `.mtf` 输入能力

- `moon run cmd/main` 继续保留跨目标可跑的嵌入样例模式。
- 新增 `scripts/analyze_model.ps1`，通过环境变量桥接真实 `.mtf` 文件内容，再复用
  `cmd/main` 输出文本或 JSON 结果。
- 该设计避免为读取文件而破坏核心包的跨目标检查能力。

### 2.4 CI 与验收脚本

- 重写 `.github/workflows/ci.yml` 为三平台矩阵。
- CI 明确包含：
  `moon update`
  `moon check --target all`
  `moon test --target all`
  `moon fmt` + `git diff --exit-code`
  `moon info` + `git diff --exit-code`
  `moon run cmd/main`
- 新增 `scripts/verify_acceptance.ps1`，把 README、LICENSE、CI、Mooncakes、默认分支、
  贡献者身份、源码规模和真实 fixture 分析都固定为可重复步骤。

## 3. 与预验收意见的对应关系

### 3.1 关于命令兼容性

组委会意见中提到 `moon fmt --deny-warn` 与 `moon info --deny-warn`。
在当前本地 MoonBit 0.10.3 CLI 上，这两个命令并不被接受。

因此本仓库不伪造“它们可以通过”，而是采用与社区模板一致、且当前工具链真实
支持的替代验收方式：

- `moon fmt` 后检查 `git diff --exit-code`
- `moon info` 后检查 `git diff --exit-code`

### 3.2 关于 CI 缺失

已按当前 MoonBit 社区模板方向补齐三平台 CI，并加入 `moon update`、全目标检查、
全目标测试以及无 diff 校验。

### 3.3 关于“实现规模较小”

当前仓库仍低于官方页面给出的 `4~10k LOC` 参考区间，但已经不再停留在单文件
解析和简单路径检查阶段，而是向以下方向补强：

- 更清晰的工程模块化组织；
- 更真实的数据流 fixture；
- JSON 输出；
- 更完整的边界测试；
- 自查脚本、CHANGELOG、来源说明和双远程核查材料。

当前跟踪的 `.mbt` / `.mbti` 规模约为 `1026` 行，后续若继续冲刺正式验收，
建议优先增加：

- AST / 调用图适配入口；
- fixture 到报告的批处理能力；
- 更明确的 service / namespace 分组策略；
- 更系统的性能基准。

## 4. 当前验证基线

本地已验证：

```bash
moon check --target all
moon test
moon fmt
moon info
moon run cmd/main
powershell -ExecutionPolicy Bypass -File scripts\analyze_model.ps1 -Path fixtures\models\webapp_taint.mtf -Json
```

本机限制：

- 当前 Windows 环境没有系统 C 编译器，因此本地不能把
  `moon test --target all` 的 native 结果当作已完成事实。

CI 负责覆盖：

- `moon test --target all`
- 三平台一致性

## 5. 关于身份与公开历史

- 当前后续维护身份统一为 `llgllg <1357801557@qq.com>`。
- 旧账号、旧名字、旧邮箱若已经存在于公开历史中，本轮不通过改写历史移除。
- GitLink “虚拟贡献者”若仍出现，优先按平台统计问题记录来源，不通过重写历史处理。
