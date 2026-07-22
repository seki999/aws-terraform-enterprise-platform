# Terraform 命令手册

> 示例默认在环境根目录执行。任何 `apply`、`destroy`、`state push`、`state rm`、`force-unlock` 都必须先备份、审查并获得授权。命令输出和 `TF_LOG` 可能含敏感值。

## 返回码约定

一般命令成功为 0、失败为非 0。`terraform plan -detailed-exitcode` 特殊：0 表示无变更，1 表示错误，2 表示有变更。CI 必须把 2 当作成功且需要审查，不能直接按普通非零规则失败。

## 基础命令

### `terraform version`

- 作用/场景：显示 Core、平台和已初始化 Provider 版本；故障排查和 CI 首步。
- 参数/示例：`terraform version -json` 便于机器读取。
- 风险：无云变更；但版本输出可能暴露内部工具基线。
- 实践：将版本范围写入 `versions.tf`，实际选择写入 Lockfile。
- 常见错误：本机版本不满足 `required_version`，需升级或使用版本管理器。

### `terraform help`

- 作用/场景：查看命令或子命令帮助。
- 参数/示例：`terraform help plan`、`terraform state -help`。
- 风险：无。
- 实践：以当前安装版本的帮助为准，不机械复制旧博客参数。
- 常见错误：把全局参数放到错误位置。

### `terraform init`

- 作用/场景：初始化 Backend、下载 Provider、安装模块、写 Lockfile。
- 参数/示例：`terraform init -backend-config=backend.hcl -input=false`。
- 风险：可能迁移/读取远程 State，且会创建本地 `.terraform`；不会创建业务资源。
- 实践：先审查 Backend 配置；CI 使用 `-input=false`。
- 常见错误：缺少 Bucket/KMS 权限、Module 路径错误、代理阻断 Provider 下载。

### `terraform init -upgrade`

- 作用/场景：在版本约束内重新选择较新 Provider/Module。
- 参数/示例：`terraform init -upgrade -backend=false`。
- 风险：可能改变 Lockfile 和 Provider 行为。
- 实践：单独升级 PR，阅读 Changelog，跑完整 Plan/Test。
- 常见错误：约束仍阻止目标版本，或未提交更新后的 Lockfile。

### `terraform init -reconfigure`

- 作用/场景：忽略已缓存 Backend 配置并使用新配置。
- 参数/示例：`terraform init -reconfigure -backend-config=backend.hcl`。
- 风险：指向错误 State 会产生“全部新建”Plan。
- 实践：先核对 Bucket、Key、Region、KMS 和账号。
- 常见错误：把 `-reconfigure` 当成 State 迁移；它不会自动迁移旧 State。

### `terraform init -migrate-state`

- 作用/场景：Backend 变更时迁移已有 State。
- 参数/示例：修改 Backend 后运行 `terraform init -migrate-state`。
- 风险：高；错误目标、并发写入或中断可能影响 State。
- 实践：先 `state pull` 加密备份，冻结变更，验证目标，再迁移。
- 常见错误：目标 Backend 权限或 KMS 权限不足。

### `terraform fmt` 与 `terraform fmt -recursive`

- 作用/场景：按 Terraform 标准格式重写 HCL；recursive 覆盖子目录。
- 参数/示例：CI 用 `terraform fmt -check -recursive -diff`。
- 风险：只改文件格式，不改云资源；仍应审查 Diff。
- 实践：提交前运行 recursive；CI 用 check 不改文件。
- 常见错误：在错误目录只格式化一个根模块。

### `terraform validate`

- 作用/场景：校验语法、类型、Provider Schema 和模块接口。
- 参数/示例：先 `terraform init -backend=false`，再 `terraform validate -json`。
- 风险：不创建资源，但初始化会下载插件。
- 实践：对 Bootstrap 和三个环境根模块分别执行。
- 常见错误：未 Init、Provider 未安装、依赖模块地址无效。

### `terraform plan`

- 作用/场景：刷新远端对象并计算变更。
- 参数/示例：`terraform plan -var-file=terraform.tfvars`。
- 风险：通常只读 AWS，但 Provider/Data Source 可能有特殊行为；Plan 可能含敏感数据。
- 实践：用只读/Plan Role、显式环境、保存 Plan、人工审查。
- 常见错误：错误账号/Region/State、缺少凭证、变量或配额数据源失败。

### `terraform apply`

- 作用/场景：执行 Plan；无 Plan 文件时会现场生成并请求确认。
- 参数/示例：推荐 `terraform apply tfplan`。
- 风险：创建、修改或删除真实资源。
- 实践：生产只 Apply 已审查的保存 Plan，并使用审批保护。
- 常见错误：Plan 过期、State Lock、权限不足、资源配额或名称冲突。

### `terraform destroy`

- 作用/场景：生成并执行全部托管资源的销毁。
- 参数/示例：更安全地先 `terraform plan -destroy -out=destroy.tfplan`，再 `terraform apply destroy.tfplan`。
- 风险：极高；数据、日志和入口可被删除。
- 实践：备份、确认环境、审查 Final Snapshot/Deletion Protection、先清非关键环境。
- 常见错误：S3 非空、RDS 删除保护、Backup 保留、依赖或权限阻止删除。

### `terraform show`

- 作用/场景：显示当前 State 或保存 Plan。
- 参数/示例：`terraform show`、`terraform show tfplan`、`terraform show -no-color tfplan`。
- 风险：可能输出敏感值。
- 实践：Plan 文本仅存受控位置；发布摘要前检查脱敏。
- 常见错误：Plan 由不同 Terraform 版本生成而无法读取。

### `terraform output`

- 作用/场景：读取 Root Output。
- 参数/示例：`terraform output -raw alb_dns_name`、`terraform output -json`。
- 风险：`-json` 仍会包含 sensitive Output 的真实值。
- 实践：脚本只读取所需非敏感单项。
- 常见错误：尚未 Apply、Output 名错误或值为 null。

### `terraform console`

- 作用/场景：交互评估表达式、变量、函数与 State 值。
- 参数/示例：输入 `cidrsubnet("10.0.0.0/16", 8, 10)`。
- 风险：能读取敏感 State 内容，终端历史可能记录输入。
- 实践：只在受控终端使用，退出用 Ctrl-D。
- 常见错误：未初始化或引用当前 Root 不存在的地址。

### `terraform graph`

- 作用/场景：输出 DOT 依赖图。
- 参数/示例：`terraform graph | dot -Tsvg > graph.svg`。
- 风险：无云变更；图中可能暴露内部资源名。
- 实践：用于诊断循环依赖，不把完整生产图公开。
- 常见错误：未安装 Graphviz 的 `dot`。

### `terraform providers`

- 作用/场景：显示 Provider 需求树与 State 中 Provider。
- 参数/示例：`terraform providers`。
- 风险：无。
- 实践：升级和排查版本冲突时使用。
- 常见错误：不同子模块的约束没有交集。

### `terraform get`

- 作用/场景：下载或更新配置中引用的模块；现代工作流通常由 `init` 完成。
- 参数/示例：`terraform get -update`。
- 风险：更新模块可能改变代码。
- 实践：优先 `terraform init`；只在明确只处理模块时使用。
- 常见错误：私有 Module 凭证或网络失败。

### `terraform refresh`

- 作用/场景：历史命令，用远端对象更新 State。
- 参数/示例：`terraform refresh -var-file=terraform.tfvars`。
- 风险：等价于自动批准的 refresh-only Apply，会写 State。
- 实践：优先 `terraform plan -refresh-only` 后 `terraform apply -refresh-only`。
- 常见错误：把远端漂移写入 State 后失去审查机会。

### `terraform test`

- 作用/场景：执行 `.tftest.hcl` Run 和 Assert。
- 参数/示例：`terraform test -verbose`、`terraform test -filter=tests/networking.tftest.hcl`。
- 风险：默认 Test 可创建真实资源，取决于测试中的 `command` 与 Mock；本项目使用 Mock + Plan。
- 实践：审查测试是否 Mock Provider，远程测试必须用隔离账号并确保清理。
- 常见错误：Module 路径相对测试运行目录错误，或未 Init Provider。

## Plan 与 Apply 变体

### 保存并执行 Plan

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show tfplan
terraform show -json tfplan > tfplan.json
terraform apply tfplan
```

- `-out` 把审查与执行绑定到同一变更集，减少代码/State 漂移窗口。
- 二进制 Plan 和 JSON 都可能含敏感值；不得提交 Git，Artifact 要最小权限和短保留。
- `terraform show -json tfplan` 适合策略、成本和机器分析，但风险高于普通脱敏文本。
- Plan 在配置、Provider、变量或 State 变化后应重新生成。

### `terraform apply -auto-approve`

- 作用/场景：跳过交互确认，适合受保护 CI 执行已建立审批门的操作。
- 风险：直接对未保存的现场 Plan 自动执行，生产中容易把错误环境或未审查删除落地。
- 实践：生产优先 `apply tfplan`；把审批放在 CI Environment，而不是依赖交互提示。
- 常见错误：误以为 auto-approve 等于安全自动化。

### `terraform plan -destroy`

- 作用/场景：只生成销毁计划。
- 示例：`terraform plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan`。
- 风险：Plan 本身只读，但后续 Apply 会删除资源。
- 实践：逐项确认持久数据、快照、日志、DNS 和 Backend 不在错误范围。
- 常见错误：忽略 Deletion Protection 或外部依赖。

### Refresh-only

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

- 作用/场景：接受远端对象变化并只更新 State/Output，不修改远端资源。
- 风险：Apply 会写 State，可能把未经批准的 Drift 固化为基线。
- 实践：先保存/审查 Plan；判断应该接受 Drift 还是把资源修回代码。
- 常见错误：用 refresh-only 期待修复远端配置。

### `-detailed-exitcode`

```bash
terraform plan -detailed-exitcode
case $? in
  0) echo "no changes" ;;
  1) echo "plan failed"; exit 1 ;;
  2) echo "changes require review" ;;
esac
```

CI 常见错误是把返回码 2 当成失败，或用 `continue-on-error` 同时吞掉返回码 1。

### `-target`

```bash
terraform plan -target=module.networking
terraform apply -target=module.networking
```

- 作用/场景：故障恢复或打破临时依赖时只处理目标及其依赖。
- 风险：产生不完整 Plan，跳过配置中的其他变更，使 State 与架构长期不一致。
- 实践：不是日常分阶段部署工具；使用后立即运行完整 Plan 并清零差异。
- 常见错误：用 Target 长期管理“层”，而不拆分 State/Root。

### `-replace`

```bash
terraform plan -replace=aws_instance.example
terraform apply -replace=aws_instance.example
```

- 作用/场景：资源异常或不可修复时要求重建。
- 风险：可能停机、替换 IP/Endpoint 或丢失本地数据。
- 实践：先 Plan，确认生命周期、备份和依赖；优先于 `terraform taint`。
- 常见错误：资源地址含索引时 Shell 引号不正确。

## State 命令

State 是 Terraform 对真实对象的映射和属性快照，不是真实资源本身。修改 State 不等于修改 AWS；但错误映射会导致后续 Plan 创建、修改或删除错误对象。

操作前：

```bash
terraform state pull > backup-$(date +%Y%m%d%H%M%S).tfstate
# 将备份移入受控加密存储，不提交 Git。
terraform plan
```

### `terraform state list`

- 作用/场景：列出 State 地址；迁移、Import、诊断前定位对象。
- 参数/示例：`terraform state list 'module.data.*'`。
- 风险：只读，但资源命名可能敏感。
- 实践：在精确环境 Backend 下执行。
- 常见错误：初始化了错误 State Key 而看到空列表。

### `terraform state show`

- 作用/场景：显示单个 State 对象。
- 参数/示例：`terraform state show 'module.data.aws_db_instance.postgres[0]'`。
- 风险：可能输出密码和敏感属性。
- 实践：不要粘贴到 Issue/Chat；完成后清理终端记录。
- 常见错误：地址中的方括号未加引号。

### `terraform state mv`

- 作用/场景：重命名资源地址或在重构后迁移映射。
- 参数/示例：`terraform state mv old.address new.address`；跨 State 用 `-state-out` 风险更高。
- 风险：源/目标错误会造成后续 Destroy/Create。
- 实践：优先使用 `moved` Block 保留可审计历史；先备份、后完整 Plan。
- 常见错误：配置尚未同步到新地址。

### `terraform state rm`

- 作用/场景：让 Terraform 停止管理对象。
- 参数/示例：`terraform state rm 'aws_s3_bucket.legacy'`。
- 风险：不会删除真实 AWS 资源；下一次 Plan 可能按配置创建同名资源并冲突。
- 实践：只用于明确的移交/修复，先备份并记录资源新所有者。
- 常见错误：误认为它能清理 AWS 资源。

### `terraform state pull`

- 作用/场景：从 Backend 输出当前 State，用于受控备份和诊断。
- 参数/示例：`terraform state pull > backup.tfstate`。
- 风险：输出包含全部敏感值。
- 实践：限制文件权限、加密保存、禁止提交、及时清理。
- 常见错误：把输出打印到 CI 日志。

### `terraform state push`

- 作用/场景：把本地 State 强制写回 Backend，仅限灾难恢复。
- 参数/示例：`terraform state push recovered.tfstate`。
- 风险：极高，可覆盖较新 State；`-force` 可绕过 lineage/serial 保护。
- 实践：冻结所有写操作、双人复核、验证 lineage/serial、先备份远端，尽量避免。
- 常见错误：把旧备份推到新 State。

### `terraform state replace-provider`

- 作用/场景：替换 State 中 Provider Source 地址，例如 Fork 迁回官方 Provider。
- 参数/示例：`terraform state replace-provider old/source hashicorp/aws`。
- 风险：写 State，错误 Provider 可能无法解释资源 Schema。
- 实践：备份、锁定 Provider 版本、先在副本验证。
- 常见错误：只改配置未改 State，出现 Provider Configuration Not Present。

## Import

### 传统 CLI Import

```bash
terraform import 'aws_s3_bucket.existing' existing-bucket-name
terraform plan
```

- 作用：把既有 AWS 对象绑定到已存在的 Terraform Resource 地址。
- 风险：Import 只写 State，不自动生成完整配置；配置不一致时下一 Plan 可能修改/替换对象。
- 实践：先写匹配配置、备份 State、Import、运行完整 Plan，直到意外差异为零。
- 常见错误：ID 格式错误、错误账号/Region、地址含 `for_each` Key 未正确引用。

### Import Block

```hcl
import {
  to = aws_s3_bucket.example
  id = "existing-bucket-name"
}
```

运行 `terraform plan` 预览并 `apply` 完成 Import。Import Block 可审查、可进入 CI，并能批量迁移；成功后可保留作为历史或按团队规范移除。

无论 CLI 还是 Block，Import 后都必须补齐资源配置、关联资源、Lifecycle 和安全设置。Drift 检查使用完整 `terraform plan`；不要用 Target 掩盖未建模属性。

## Workspace

```bash
terraform workspace list
terraform workspace show
terraform workspace new experiment
terraform workspace select experiment
terraform workspace delete experiment
```

- list/show：只读查看；常见错误是忽略当前 Workspace。
- new/select：切换同一配置下的 State 命名空间；切换后完整 Plan。
- delete：只删除 Workspace State 入口，要求 Workspace 非当前且通常为空；不会代替资源销毁。
- 风险：Workspace 共用代码、Backend、Provider 凭证和通常相同权限，容易误操作。
- 适用：同安全边界内的临时副本或实验。
- 本项目：dev/staging/prod 需要独立目录、变量、State Key、IAM 和审批，所以不用 Workspace 代替环境隔离。

## Taint 历史

`terraform taint ADDRESS` 把对象标记为下次替换，`terraform untaint ADDRESS` 清除标记。Taint 会立即写 State，审查边界较差，现已不推荐。

优先：

```bash
terraform plan -replace=ADDRESS -out=tfplan
terraform show tfplan
terraform apply tfplan
```

`-replace` 把替换意图保留在一次 Plan 中，不永久修改 State。旧自动化如仍用 taint，应迁移并验证。

## Provider 与依赖

### `terraform providers lock`

- 作用/场景：预先选择 Provider 并写多平台 Hash。
- 示例：`terraform providers lock -platform=linux_amd64 -platform=windows_amd64`。
- 风险：更改 Lockfile。
- 实践：在受信任网络生成，审查版本与 Hash，提交 Lockfile。
- 常见错误：只包含开发平台 Hash，CI 初始化失败。

### `terraform providers mirror`

- 作用/场景：为离线/受控网络创建 Provider Mirror。
- 示例：`terraform providers mirror -platform=linux_amd64 ./mirror`。
- 风险：Mirror 二进制需要供应链保护，且占用空间。
- 实践：校验 Hash/签名，通过 CLI Config 指向只读内部 Mirror。
- 常见错误：Mirror 缺少目标平台或版本。

### `terraform providers schema -json`

- 作用/场景：导出 Provider/Resource Schema 供工具分析。
- 示例：`terraform providers schema -json > provider-schema.json`。
- 风险：无云变更；文件较大并暴露内部 Provider 使用情况。
- 实践：初始化后运行，生成物不必提交。
- 常见错误：Provider 尚未安装。

### Lockfile 与 CI 缓存

`.terraform.lock.hcl` 记录 Provider 版本与校验 Hash，不记录 Module 版本。CI 可缓存 Provider 下载目录，但必须以 Lockfile Hash 为 Cache Key；绝不缓存 State、Plan 或凭证。升级只在独立 PR 使用 `init -upgrade`。

## Debug

Linux/macOS：

```bash
TF_LOG=DEBUG terraform plan
TF_LOG=TRACE TF_LOG_PATH=terraform.log terraform apply
```

PowerShell：

```powershell
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "terraform.log"
terraform plan
Remove-Item Env:TF_LOG, Env:TF_LOG_PATH
```

- DEBUG/TRACE 可暴露请求、Header、路径、State 与敏感值。
- 只在最短时间启用，写受控本地文件，问题解决后安全删除。
- `terraform.log` 已 Git Ignore；这不是发布到 Issue 的许可。
- 常见错误：忘记清除环境变量，导致后续 CI/终端持续打印敏感日志。

## 变量传递与优先级

从低到高：

1. Variable `default`；
2. 自动加载 `terraform.tfvars`；
3. 按文件名顺序加载 `*.auto.tfvars`；
4. `-var-file`，后出现者覆盖先出现者；
5. `-var`，后出现者覆盖；
6. `TF_VAR_name` 在没有更高优先级 CLI 值时使用。环境变量相对自动文件的精确行为应通过当前版本文档和小实验确认，不把 Shell 中的值当作可审计配置。

示例：

```bash
terraform plan
terraform plan -var-file=dev.tfvars
terraform plan -var='ecs_desired_count=1'
TF_VAR_environment=dev terraform plan
```

原则：

- 非敏感环境差异使用受审查 tfvars；真实 `terraform.tfvars` 不提交。
- Secret 不用 `-var`（会进入 Shell 历史），优先由 Secrets Manager/外部凭证流程提供。
- CI 记录变量来源但不打印值。
- 常见错误：同一变量在多个来源定义，导致实际优先级与预期不同。

## 常用工作流

### 新环境初始化

```bash
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show tfplan
terraform apply tfplan
```

Apply 仅在明确授权和审查后执行。

### 修改基础设施

1. 修改模块、变量示例和文档。
2. `terraform fmt -recursive`。
3. `terraform validate && terraform test`。
4. TFLint/Checkov/Trivy。
5. 保存 Plan，审查 Create/Update/Replace/Delete 和敏感项。
6. 人工批准后 Apply 保存 Plan。
7. Smoke Test 和完整 Plan 确认无意外差异。

### 导入已有资源

1. 备份 State。
2. 写与远端匹配的 Resource 配置。
3. 添加 Import Block 或执行 CLI Import。
4. Plan，补齐属性，直到无破坏性差异。
5. 应用 Import，复查 State/Plan，记录所有权。

### 修复 State

1. 冻结 CI/人工写操作。
2. `state pull` 受控备份。
3. 优先 `moved` Block 或 `state mv`。
4. 双人复核任何 rm/push。
5. 完整 Plan；确认真实资源与 State 一一对应。
6. 记录命令、操作者、时间、备份位置和恢复方案。

### 只刷新 State

```bash
terraform plan -refresh-only -out=refresh.tfplan
terraform show refresh.tfplan
terraform apply refresh.tfplan
```

先判断 Drift 是否应该被接受；否则修复远端或配置，而不是刷新。

### 替换单个资源

```bash
terraform plan -replace='ADDRESS' -out=replace.tfplan
terraform show replace.tfplan
terraform apply replace.tfplan
```

先验证备份、停机影响、DNS/Endpoint 变化和依赖。

### 销毁开发环境

```bash
terraform plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```

之后检查残留 S3、Snapshot、ECR Image、Log Group、ENI、NAT/EIP 和 Backup Recovery Point。Backend 最后处理。

### CI/CD

1. PR：fmt、validate、test、lint、安全扫描。
2. OIDC Assume Plan Role。
3. `plan -detailed-exitcode -out=tfplan`；正确处理 0/1/2。
4. 生成不公开的审查摘要，短期保存二进制 Plan。
5. Protected Environment 人工批准。
6. Apply 同一 Plan；Smoke Test；完整 Plan 校验。
7. 禁止在 Fork PR 暴露 Role 或 Secret。

