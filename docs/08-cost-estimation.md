# 成本估算与控制

本项目不提供虚构的精确价格。价格随区域、日期、用量、购买模型和税费变化；部署前使用 AWS Pricing Calculator，部署后使用 Cost Explorer、Budgets 和账单告警。

## 主要持续收费资源

| 资源 | 固定/空闲风险 | 流量/用量风险 | 控制 |
| --- | --- | --- | --- |
| NAT Gateway | 按小时 | 每 GB、跨 AZ | dev 关闭/单 NAT；prod 同 AZ；优先 Gateway Endpoint |
| Interface Endpoint | 每 AZ/小时 | 数据处理 | 按需开启，减少服务/AZ |
| ALB | 按小时 | LCU | dev 默认关闭，实验后销毁 |
| RDS | 实例、存储 | I/O、备份、PI | 小规格、Single-AZ dev、短保留 |
| Redis | 节点 | Snapshot/流量 | dev 默认关闭 |
| ECS Fargate | Task 运行期间 | CPU/内存 | desired=1，空闲缩 0 |
| EC2/EBS/EIP | 实例/卷；闲置 EIP | 出站 | 默认关闭，定时停止 |
| WAF | ACL/Rule | 请求 | dev 默认关闭，控制 Rule |
| CloudWatch | 自定义指标/Logs | 摄取、查询 | 短保留、结构化精简日志 |
| Config/GuardDuty | 记录/分析 | 事件量 | 组织统管或按环境开启 |
| Backup | Recovery Point 存储 | 跨区/恢复 | 生命周期、定期清理 |
| CodePipeline/CodeBuild | Pipeline/构建 | 分钟、Artifact | 默认关闭 |
| CloudFront | 低固定风险 | 请求/出站 | Price Class、缓存 |
| S3/ECR | 存储 | 请求/传输 | Lifecycle、镜像保留 20 |
| DynamoDB/Lambda/SQS/SNS | 多为按用量 | 请求/执行/消息 | On-demand、限流、重试上限 |

## 免费或低成本能力

VPC、Route Table、Security Group、NACL、IGW 本身通常没有直接小时费，但流量、Public IPv4、NAT、Flow Logs 和关联服务可能收费。不能把“资源本身免费”理解为路径免费。

## 固定费用与流量费用

固定风险重点是 NAT、Interface Endpoint、ALB、数据库/缓存节点和持续运行计算。流量风险重点是 NAT 数据处理、跨 AZ、互联网出站、CloudFront 和日志摄取。架构评审必须同时画出流量路径。

## 服务风险

### NAT Gateway

即使无业务流量也按小时计费。单 NAT 降低 dev 成本但引入 AZ 单点和跨 AZ 费。无 NAT 必须补齐工作负载所需 Endpoint，且第三方公网依赖仍不可达。

### ALB

按小时和 LCU；一个低流量实验也会持续收费。关闭 ECS 不会自动消除 ALB。

### RDS

实例和存储持续收费；Multi-AZ、备份超额、Performance Insights、IOPS 增加成本。Final Snapshot 继续占用存储。

### Redis

节点持续收费，Multi-AZ 至少多个节点；Snapshot 也占存储。dev 默认关闭。

### CloudWatch Logs

高日志量、长保留、Insights 查询和自定义指标均可能快速增长。禁止 Debug 常开和完整 Payload 记录。

## 降本方法

- 使用附件提供的低成本 tfvars 作为起点；
- 实验按模块逐步开启，完成即销毁；
- ECS desired count 1 或 0；
- RDS 小规格、Single-AZ dev；
- Redis/EC2/治理/Code* 默认关闭；
- S3/ECR/Log Lifecycle；
- 使用 DynamoDB On-demand；
- 控制 Lambda Retry、SQS Retention 与日志；
- 非生产定时停止 EC2/数据库需另行评估自动化；
- 为资源强制 CostCenter/Environment 标签。

## 部署前检查

- [ ] Pricing Calculator 已覆盖东京区和 us-east-1 的 CloudFront/WAF/ACM相关项
- [ ] NAT/Endpoint 二选一或组合路径有成本比较
- [ ] ALB/RDS/Redis/Fargate 小时数
- [ ] 日志量、保留、查询
- [ ] 跨 AZ/互联网/NAT 数据路径
- [ ] Backup、Snapshot、ECR/S3 保留
- [ ] 预算、告警和负责人
- [ ] 试验结束时间与销毁负责人

## 销毁后检查

- [ ] Terraform State 与 Destroy 结果
- [ ] NAT/EIP、ALB、EC2/EBS、Fargate
- [ ] RDS/Redis、Snapshot、Backup Recovery Point
- [ ] Interface Endpoint/ENI
- [ ] S3/ECR/CloudWatch Logs
- [ ] Route 53/ACM/WAF/CloudFront
- [ ] Config/GuardDuty/Trail/Code*
- [ ] 次日 Cost Explorer 与账单告警

成本数据有延迟，销毁后立即“看不到费用”不能证明没有残留。

