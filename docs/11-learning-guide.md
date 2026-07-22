# 学习路线

## 使用方式

每阶段先读代码和文档，再运行不会改变云资源的本地命令。控制台观察或真实实验只在用户授权的 Sandbox 中进行。任何 Apply/Destroy 都必须单独批准并记录成本。

## 1. Terraform 基础

- **学习目标：** 理解 HCL、Resource、Variable、Output、Module 和依赖图。
- **阅读代码：** `environments/dev`、`modules/platform`。
- **执行命令：** `terraform fmt -check -recursive`、`init -backend=false`、`validate`、`console`。
- **观察控制台：** 本阶段不需要控制台。
- **实验任务：** 修改 dev 的日志保留并观察 Validate；不要 Apply。
- **思考题：** Variable validation 与 Provider validation 有何边界？。
- **清理方法：** 删除本地 `.terraform` 可重新 Init；保留 Lockfile。

## 2. State 与 Provider

- **学习目标：** 理解 State、Lock、Backend、Provider约束与Lockfile。
- **阅读代码：** `bootstrap/backend`、三个 `versions.tf`。
- **执行命令：** `providers`、`providers lock`、`state list`（仅有真实State时）。
- **观察控制台：** S3 Versioning、KMS、IAM。
- **实验任务：** 在隔离副本比较不同 State Key；不执行 state push。
- **思考题：** 为什么 sensitive 不会从 State 删除值？。
- **清理方法：** 删除临时本地 State；不要删远程 State。

## 3. VPC

- **学习目标：** 掌握CIDR、三层Subnet、路由、NAT、Endpoint。
- **阅读代码：** `modules/networking`、网络图。
- **执行命令：** `terraform test -filter=tests/networking.tftest.hcl`。
- **观察控制台：** VPC、Subnet、Route、Endpoint、Flow Logs。
- **实验任务：** 为第三AZ规划不重叠CIDR并通过检查。
- **思考题：** 无 NAT 的 ECS 拉镜像需要哪些 Endpoint？。
- **清理方法：** 只做Mock Plan无需云清理；真实实验按VPC依赖反向销毁。

## 4. IAM

- **学习目标：** 掌握Role、Trust Policy、Permission Policy、OIDC。
- **阅读代码：** `modules/identity`、各服务IAM Policy。
- **执行命令：** `terraform providers schema -json`、Checkov。
- **观察控制台：** IAM Role、Access Analyzer、CloudTrail。
- **实验任务：** 为只读DynamoDB角色写资源级Policy。
- **思考题：** 何时 Resource `*` 无法避免，如何记录？。
- **清理方法：** 删除临时Role/Policy并检查未使用凭证。

## 5. S3 与 CloudFront

- **学习目标：** 掌握私有Origin、OAC、缓存、证书区域。
- **阅读代码：** `modules/frontend`。
- **执行命令：** Plan并检查Bucket Policy，不Apply。
- **观察控制台：** S3 Public Access、CloudFront、ACM us-east-1。
- **实验任务：** 本地审查自定义域名条件分支。
- **思考题：** 为何CloudFront证书不在东京？。
- **清理方法：** 禁用CloudFront/域名后Plan；真实实验清Bucket前先备份。

## 6. ECS 与 ALB

- **学习目标：** 掌握Task/Service、Fargate网络、健康检查和伸缩。
- **阅读代码：** `modules/compute`、`application/api`。
- **执行命令：** `docker build application/api`、`pytest`。
- **观察控制台：** ECR、ECS Service Event、Target Health。
- **实验任务：** 本地运行API并使Health Check通过。
- **思考题：** Execution Role与Task Role为何分离？。
- **清理方法：** 停止Compose；真实实验先缩Task再销毁ALB/ECS。

## 7. RDS、DynamoDB、Redis

- **学习目标：** 比较关系、NoSQL与缓存的数据模型和恢复。
- **阅读代码：** `modules/data`、API Services。
- **执行命令：** Python测试、Plan并检查公开/加密字段。
- **观察控制台：** RDS、DynamoDB、ElastiCache。
- **实验任务：** 设计Job TTL与GSI查询；不需要真实数据。
- **思考题：** 缓存丢失时系统如何降级？。
- **清理方法：** 删除测试数据；真实销毁前Snapshot/PITR确认。

## 8. Lambda、API Gateway

- **学习目标：** 理解Proxy事件、Layer、权限、日志与限流。
- **阅读代码：** `modules/serverless`、Validator。
- **执行命令：** `pytest application/lambda/tests`。
- **观察控制台：** Lambda、API Gateway、CloudWatch Logs。
- **实验任务：** 为Validator增加一个无副作用校验测试。
- **思考题：** API 202 与后台处理失败如何关联？。
- **清理方法：** 删除测试函数/Stage；保留失败日志证据。

## 9. SQS、SNS、EventBridge

- **学习目标：** 掌握至少一次、DLQ、通知与事件路由。
- **阅读代码：** Serverless消息资源、Consumer。
- **执行命令：** Terraform Test、Lambda单测。
- **观察控制台：** SQS Metrics/Redrive、SNS Subscription、EventBridge Rule。
- **实验任务：** 模拟一条失败Record并验证部分批失败。
- **思考题：** Visibility Timeout、Lambda Timeout和Retry如何配合？。
- **清理方法：** 清空/保留DLQ证据后删除Queue，取消订阅。

## 10. Step Functions

- **学习目标：** 理解状态、Retry、服务集成和执行历史。
- **阅读代码：** State Machine定义、Worker。
- **执行命令：** 检查 `jsonencode` 定义、Worker测试。
- **观察控制台：** Step Functions Graph/Execution。
- **实验任务：** 为Worker失败设计Catch与告警方案。
- **思考题：** Lambda重试和State Retry叠加有什么风险？。
- **清理方法：** 等待/停止Execution并删除测试状态机。

## 11. CloudWatch

- **学习目标：** 建立指标、日志、Dashboard和告警思维。
- **阅读代码：** `modules/operations`、日志配置。
- **执行命令：** 检查13类Alarm资源、运行应用Metrics。
- **观察控制台：** Dashboard、Alarm History、Log Insights。
- **实验任务：** 构造DLQ告警演练方案。
- **思考题：** Missing Data 应视为正常还是故障？。
- **清理方法：** 删除临时日志查询/告警，保留演练记录。

## 12. CloudTrail 与 Config

- **学习目标：** 区分API审计和配置合规。
- **阅读代码：** Operations审计Bucket/Trail/Config。
- **执行命令：** Checkov与Bucket Policy审查。
- **观察控制台：** CloudTrail Event History、Config Timeline。
- **实验任务：** 设计S3公开读取合规修复流程。
- **思考题：** 组织级Recorder与环境Recorder为何冲突？。
- **清理方法：** 真实实验先确认组织所有权，再停Recorder/Trail。

## 13. CI/CD

- **学习目标：** 理解PR质量门、保存Plan、OIDC和审批。
- **阅读代码：** `.github/workflows`、`modules/cicd`。
- **执行命令：** 本地复现Workflow中的fmt/validate/test。
- **观察控制台：** GitHub Actions、IAM OIDC、CodePipeline。
- **实验任务：** 解释 detailed-exitcode 0/1/2并修复模拟脚本。
- **思考题：** 为何上传Plan Artifact也有敏感风险？。
- **清理方法：** 删除临时Artifact/Connection，撤销测试Role会话。

## 14. 安全扫描

- **学习目标：** 理解IaC、Secret、依赖、镜像和误报治理。
- **阅读代码：** Checkov/Trivy/Gitleaks工作流、Dockerfile。
- **执行命令：** `tflint --recursive`、`checkov -d .`、`trivy fs .`。
- **观察控制台：** Security Hub/Inspector可作为后续扩展。
- **实验任务：** 选择一个告警并记录风险、补偿控制、复审日期。
- **思考题：** 为什么不能为了全绿静默Skip？。
- **清理方法：** 移除临时扫描输出，保留受控报告。

## 15. 生产化设计

- **学习目标：** 综合高可用、成本、RTO/RPO、变更与组织治理。
- **阅读代码：** 全部文档、prod变量、验证报告。
- **执行命令：** 完整静态门、保存Plan、成本检查；仍不自动Apply。
- **观察控制台：** Service Quotas、Cost Explorer、Backup、Health Dashboard。
- **实验任务：** 完成一次桌面灾备与变更回滚评审。
- **思考题：** 单区域多AZ还缺哪些生产能力？。
- **清理方法：** 按销毁指南清Sandbox，核对残留与账单。

## 学习完成标准

- 能解释 Plan、State 与真实资源的区别；
- 能定位网络、IAM、运行时和数据层故障；
- 能从安全、成本、可用性和恢复四个维度审查 Plan；
- 能真实记录运行/失败/缺工具/缺凭证/安全限制；
- 能在不使用长期密钥的情况下设计 OIDC CI；
- 能完成一次有证据的恢复和销毁演练。

