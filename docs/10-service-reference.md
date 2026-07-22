# AWS 服务参考

本页覆盖需求列出的 40 个服务/组件。默认启用状态以 dev 的 `terraform.tfvars.example` 为准：基础低成本资源（VPC组件、S3、ECR、DynamoDB、KMS、IAM、Secrets/Parameter、CloudWatch Alarm Topic）由组合模块创建；持续计费、域名、组织级治理与云端 CI/CD 默认关闭。

## 1. Amazon VPC

- **作用、项目用途与连接：** 隔离网络边界；承载全部私网资源。
- **关键 Terraform Resource：** `aws_vpc`。
- **关键变量：** `vpc_cidr`、`availability_zones`。
- **安全与成本：** DNS 开启、Flow Logs；VPC 本身低成本，流量路径收费。
- **常见故障与验证：** CIDR 重叠、配额；检查 VPC/Flow Log 与 `terraform state show`。

## 2. Public Subnet

- **作用、项目用途与连接：** 承载 ALB/NAT；连接 IGW。
- **关键 Terraform Resource：** `aws_subnet.public`。
- **关键变量：** `public_subnet_cidrs`。
- **安全与成本：** 不自动分配公网 IP；Public IPv4/NAT/流量收费。
- **常见故障与验证：** AZ/CIDR 错位；检查 Route Table 与公网 IP 设置。

## 3. Private Subnet

- **作用、项目用途与连接：** 分离应用和数据库；连接 ECS/RDS/Redis。
- **关键 Terraform Resource：** `aws_subnet.private_app`、`aws_subnet.private_db`。
- **关键变量：** 两组 Private CIDR。
- **安全与成本：** 无公网 IP；NAT/Endpoint 与跨 AZ 收费。
- **常见故障与验证：** 出站失败、CIDR 重叠；检查路由、SG、Endpoint。

## 4. Internet Gateway

- **作用、项目用途与连接：** Public Subnet 互联网入口。
- **关键 Terraform Resource：** `aws_internet_gateway`。
- **关键变量：** 由网络开关隐式创建。
- **安全与成本：** 只与 Public Route 关联；数据传输收费。
- **常见故障与验证：** 无路由或未附加；检查 IGW 状态与 `0.0.0.0/0`。

## 5. NAT Gateway

- **作用、项目用途与连接：** Private App IPv4 出站。
- **关键 Terraform Resource：** `aws_nat_gateway`、`aws_eip`。
- **关键变量：** `enable_nat_gateway`、`single_nat_gateway`。
- **安全与成本：** 不接收入站；按小时/GB，是最高成本风险之一。
- **常见故障与验证：** EIP配额、单 AZ 故障；检查 NAT 状态与同 AZ Route。

## 6. Route Table

- **作用、项目用途与连接：** 控制 Public/App/DB 流量路径。
- **关键 Terraform Resource：** `aws_route_table`、`aws_route`、Association。
- **关键变量：** Subnet CIDR、NAT策略。
- **安全与成本：** Database 无默认公网路由；错误路由可暴露或中断。
- **常见故障与验证：** 黑洞/错误关联；逐子网检查 Effective Route。

## 7. Security Group

- **作用、项目用途与连接：** 有状态工作负载防火墙。
- **关键 Terraform Resource：** `aws_security_group`。
- **关键变量：** `container_port`。
- **安全与成本：** DB/Redis仅信任 App SG；无直接费。
- **常见故障与验证：** 端口/方向错误；用 Reachability Analyzer 与 Flow Logs。

## 8. Network ACL

- **作用、项目用途与连接：** 无状态子网边界。
- **关键 Terraform Resource：** `aws_network_acl`、`aws_network_acl_rule`。
- **关键变量：** `vpc_cidr`。
- **安全与成本：** 需同时允许返回流量；无直接费。
- **常见故障与验证：** 临时端口被拦；检查规则顺序与 Flow Logs REJECT。

## 9. VPC Endpoint

- **作用、项目用途与连接：** 私网访问 S3/DDB/ECR/Logs/Secrets。
- **关键 Terraform Resource：** `aws_vpc_endpoint`。
- **关键变量：** `enable_vpc_endpoints`。
- **安全与成本：** Endpoint SG/Policy；Interface按 AZ/小时收费。
- **常见故障与验证：** Private DNS/路由缺失；从私网测试 DNS/443/ECR Pull。

## 10. Application Load Balancer

- **作用、项目用途与连接：** Public HTTP 入口与 ECS Health Check。
- **关键 Terraform Resource：** `aws_lb`、Target Group、Listener。
- **关键变量：** `enable_alb`、`container_port`。
- **安全与成本：** SG、Invalid Header Drop、访问日志；按小时/LCU。
- **常见故障与验证：** Target unhealthy/日志拒绝；检查 Target Health/Event。

## 11. Amazon ECS

- **作用、项目用途与连接：** 容器编排与服务伸缩。
- **关键 Terraform Resource：** `aws_ecs_cluster`、Service、Task Definition。
- **关键变量：** `enable_ecs`、desired/max。
- **安全与成本：** 独立 Task Role、Private Subnet；Fargate Task收费。
- **常见故障与验证：** 镜像/Role/健康失败；检查 Service Event/Stopped Reason。

## 12. AWS Fargate

- **作用、项目用途与连接：** 无服务器容器运行时。
- **关键 Terraform Resource：** ECS Task `requires_compatibilities = ["FARGATE"]`。
- **关键变量：** `ecs_cpu`、`ecs_memory`。
- **安全与成本：** 无主机 SSH，Task级隔离；按 CPU/内存/时长收费。
- **常见故障与验证：** CPU/内存组合无效；检查 Task Definition注册。

## 13. Amazon ECR

- **作用、项目用途与连接：** 保存 API 镜像。
- **关键 Terraform Resource：** `aws_ecr_repository`、Lifecycle Policy。
- **关键变量：** 镜像 URI/保留数。
- **安全与成本：** Immutable、扫描、加密；存储/扫描/传输收费。
- **常见故障与验证：** Tag 冲突/授权失败；推送版本标签并检查扫描。

## 14. Amazon EC2

- **作用、项目用途与连接：** 传统计算学习示例。
- **关键 Terraform Resource：** `aws_launch_template`。
- **关键变量：** `enable_ec2`、`instance_type`。
- **安全与成本：** Private、SSM、IMDSv2、加密 EBS；实例/EBS收费。
- **常见故障与验证：** AMI/配额/SSM失败；检查 ASG Activity/SSM Managed Node。

## 15. Auto Scaling Group

- **作用、项目用途与连接：** EC2弹性与自愈。
- **关键 Terraform Resource：** `aws_autoscaling_group`。
- **关键变量：** `enable_ec2`、min/desired/max。
- **安全与成本：** 默认 desired=0；实例运行收费。
- **常见故障与验证：** Launch失败/Capacity不足；检查 Activity History。

## 16. Amazon RDS for PostgreSQL

- **作用、项目用途与连接：** 关系型 Items 数据。
- **关键 Terraform Resource：** `aws_db_instance`、Subnet/Parameter Group。
- **关键变量：** `enable_rds`、Class、DB名、备份、Multi-AZ。
- **安全与成本：** 不公开、KMS、Secret、日志；实例/存储/备份收费。
- **常见故障与验证：** Subnet/Engine/KMS/配额；检查 Event/Endpoint/日志。

## 17. Amazon DynamoDB

- **作用、项目用途与连接：** Job状态与幂等记录。
- **关键 Terraform Resource：** `aws_dynamodb_table`。
- **关键变量：** Stream开关。
- **安全与成本：** On-demand、PITR、KMS、TTL/GSI；请求/存储收费。
- **常见故障与验证：** Key/GSI/条件写错误；Get/Query与PITR状态验证。

## 18. Amazon ElastiCache for Redis

- **作用、项目用途与连接：** 缓存与低延迟状态。
- **关键 Terraform Resource：** `aws_elasticache_replication_group`、Subnet/Parameter Group。
- **关键变量：** `enable_redis`、Node、Multi-AZ。
- **安全与成本：** 私网、TLS、Auth、KMS；节点持续收费。
- **常见故障与验证：** Token/TLS/Subnet/Multi-AZ；从App SG做 TLS Ping。

## 19. Amazon S3

- **作用、项目用途与连接：** 前端、上传、日志、State、Artifact、审计。
- **关键 Terraform Resource：** `aws_s3_bucket`及 Versioning/Encryption/Lifecycle/Policy。
- **关键变量：** Bucket后缀、Lifecycle。
- **安全与成本：** Public Access Block、TLS-only、加密；存储/请求/传输收费。
- **常见故障与验证：** 全局命名、Policy/KMS；检查 Public Access与对象版本。

## 20. Amazon CloudFront

- **作用、项目用途与连接：** 私有 S3 CDN。
- **关键 Terraform Resource：** `aws_cloudfront_distribution`、OAC。
- **关键变量：** `enable_cloudfront`、Price Class。
- **安全与成本：** HTTPS重定向、OAC、WAF；请求/出站收费。
- **常见故障与验证：** 证书区域/OAC/日志；访问默认域名并确认S3不可直读。

## 21. Amazon Route 53

- **作用、项目用途与连接：** 自定义域名和证书验证。
- **关键 Terraform Resource：** `aws_route53_record`。
- **关键变量：** `domain_name`、`hosted_zone_id`。
- **安全与成本：** 变更 DNS 需所有权；Hosted Zone/查询收费。
- **常见故障与验证：** Zone不匹配/传播；`dig` 与 ACM Validation状态。

## 22. AWS Certificate Manager

- **作用、项目用途与连接：** CloudFront TLS证书。
- **关键 Terraform Resource：** `aws_acm_certificate`、Validation。
- **关键变量：** 域名/Zone。
- **安全与成本：** CloudFront证书必须 us-east-1；公有证书通常无单独费。
- **常见故障与验证：** DNS验证挂起；检查记录名值和Region。

## 23. Amazon API Gateway

- **作用、项目用途与连接：** Serverless `POST /jobs`入口。
- **关键 Terraform Resource：** `aws_apigatewayv2_api`、Integration/Route/Stage。
- **关键变量：** `enable_serverless`。
- **安全与成本：** 限流、CORS、访问日志；请求/数据收费。
- **常见故障与验证：** 5XX/Integration权限；调用端点并检查Execution日志。

## 24. AWS Lambda

- **作用、项目用途与连接：** 验证、消费、Step Worker。
- **关键 Terraform Resource：** `aws_lambda_function`、Layer、Event Mapping。
- **关键变量：** Runtime、Role、日志保留。
- **安全与成本：** 三类独立Role、环境KMS；调用/时长/日志收费。
- **常见故障与验证：** Zip/Layer/Role/超时；单测与CloudWatch日志。

## 25. Amazon SQS

- **作用、项目用途与连接：** 异步Jobs队列与DLQ。
- **关键 Terraform Resource：** `aws_sqs_queue`、Redrive Allow Policy。
- **关键变量：** 可见性/重试。
- **安全与成本：** KMS、最小Queue权限；请求收费。
- **常见故障与验证：** 重复/积压/Visibility；发送、消费、DLQ告警演练。

## 26. Amazon SNS

- **作用、项目用途与连接：** 结果通知与告警。
- **关键 Terraform Resource：** `aws_sns_topic`、Subscription。
- **关键变量：** 邮箱可选。
- **安全与成本：** KMS、订阅需确认；投递收费。
- **常见故障与验证：** Pending/退信；检查Subscription与测试消息。

## 27. Amazon EventBridge

- **作用、项目用途与连接：** 定时触发处理流程。
- **关键 Terraform Resource：** `aws_cloudwatch_event_rule`、Target。
- **关键变量：** Schedule/Event Pattern。
- **安全与成本：** 专用Role；事件/调用收费。
- **常见故障与验证：** Rule默认Disabled/权限；启用测试后检查Invocation。

## 28. AWS Step Functions

- **作用、项目用途与连接：** 多步骤Job编排。
- **关键 Terraform Resource：** `aws_sfn_state_machine`。
- **关键变量：** Worker/SNS ARN。
- **安全与成本：** 专用Role、日志不含执行数据；按状态转换收费。
- **常见故障与验证：** Retry叠加/权限；启动测试Execution并观察每步。

## 29. AWS Secrets Manager

- **作用、项目用途与连接：** 数据库/Redis Secret。
- **关键 Terraform Resource：** `aws_secretsmanager_secret`、Version。
- **关键变量：** Recovery、KMS。
- **安全与成本：** 读取最小权限；Secret与API调用收费；值仍在State。
- **常见故障与验证：** KMS/Role/轮换；从运行Role读取但不打印。

## 30. Systems Manager Parameter Store

- **作用、项目用途与连接：** 非敏感运行配置。
- **关键 Terraform Resource：** `aws_ssm_parameter`。
- **关键变量：** 日志级别。
- **安全与成本：** 不存密码、限制读取；标准参数通常低成本。
- **常见故障与验证：** 名称/Role错误；ECS注入与参数版本检查。

## 31. AWS IAM

- **作用、项目用途与连接：** 全部服务与CI身份授权。
- **关键 Terraform Resource：** Role、Policy、Instance Profile、OIDC Provider。
- **关键变量：** GitHub Repo/Subject。
- **安全与成本：** 按主体拆分、资源级ARN；无直接费。
- **常见故障与验证：** Trust/Permission Denied；Policy Simulator/CloudTrail。

## 32. AWS KMS

- **作用、项目用途与连接：** State、数据、日志、消息、备份加密。
- **关键 Terraform Resource：** `aws_kms_key`、Alias。
- **关键变量：** 删除窗口/用途。
- **安全与成本：** 轮换、最小Key使用；Key/API调用收费。
- **常见故障与验证：** Key Policy/Region/Disabled；加解密授权与服务Event。

## 33. Amazon CloudWatch

- **作用、项目用途与连接：** Logs、Dashboard、Metrics、13类告警。
- **关键 Terraform Resource：** Log Group、Dashboard、Metric Alarm。
- **关键变量：** 保留/阈值/邮箱。
- **安全与成本：** 脱敏、KMS、短保留；摄取/查询/自定义指标收费。
- **常见故障与验证：** 维度/无数据；检查Alarm History与Dashboard。

## 34. AWS CloudTrail

- **作用、项目用途与连接：** 账号API审计。
- **关键 Terraform Resource：** `aws_cloudtrail`。
- **关键变量：** `enable_cloudtrail`。
- **安全与成本：** 多区域、完整性验证、TLS审计桶；事件/存储收费。
- **常见故障与验证：** Bucket Policy/组织冲突；检查Logging与Digest。

## 35. AWS Config

- **作用、项目用途与连接：** 资源配置历史与合规规则。
- **关键 Terraform Resource：** Recorder、Delivery Channel、Config Rule。
- **关键变量：** `enable_config`。
- **安全与成本：** 组织所有权、专用Role；Configuration Item收费。
- **常见故障与验证：** Recorder/Channel顺序/已存在；检查Recording与Rule。

## 36. AWS WAF

- **作用、项目用途与连接：** CloudFront托管规则防护。
- **关键 Terraform Resource：** `aws_wafv2_web_acl`。
- **关键变量：** `enable_waf`。
- **安全与成本：** 先Count后Block、us-east-1；ACL/Rule/请求收费。
- **常见故障与验证：** Scope/Region/误拦；Sampled Request与指标。

## 37. Amazon GuardDuty

- **作用、项目用途与连接：** 威胁检测。
- **关键 Terraform Resource：** `aws_guardduty_detector`。
- **关键变量：** `enable_guardduty`。
- **安全与成本：** 组织Detector优先；分析量收费。
- **常见故障与验证：** Detector已存在；确认组织管理和Finding。

## 38. AWS Backup

- **作用、项目用途与连接：** Vault、Plan、Selection。
- **关键 Terraform Resource：** `aws_backup_vault`、Plan、Selection。
- **关键变量：** `enable_backup`、资源ARN。
- **安全与成本：** KMS、保留；Recovery Point存储收费。
- **常见故障与验证：** Role/资源不支持/Vault非空；检查Backup Job并恢复演练。

## 39. AWS CodeBuild

- **作用、项目用途与连接：** 云端Terraform静态检查。
- **关键 Terraform Resource：** `aws_codebuild_project`。
- **关键变量：** `enable_cicd`。
- **安全与成本：** 专用Role、不Apply；构建分钟/日志收费。
- **常见故障与验证：** 镜像/Buildspec/Role；手动Build查看Phase。

## 40. AWS CodePipeline

- **作用、项目用途与连接：** GitHub到CodeBuild流水线。
- **关键 Terraform Resource：** `aws_codepipeline`、CodeStar Connection。
- **关键变量：** Repo/Branch。
- **安全与成本：** Connection需人工授权、不自动Apply；Pipeline/Artifact收费。
- **常见故障与验证：** Connection Pending/Artifact权限；提交测试分支观察Stage。

## 统一验证原则

1. 先通过 fmt、validate、terraform test、TFLint、Checkov 与 Trivy。
2. 使用 Sandbox 和只读/Plan Role生成保存 Plan。
3. 人工检查公网暴露、IAM通配、未加密存储、删除/替换、高成本资源与账号级治理冲突。
4. 获得明确授权后才 Apply。
5. 用服务控制面、CloudWatch、应用 Smoke Test 和完整 Plan 验证；控制台观察不能替代代码与 State 检查。
6. 实验完成后按销毁清单核对残留与账单。

