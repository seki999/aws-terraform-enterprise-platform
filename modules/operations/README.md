# Operations 模块

创建加密告警 SNS Topic、CloudWatch Dashboard、需求指定的 13 类告警，以及可选 CloudTrail、AWS Config、GuardDuty 和 AWS Backup。

告警仅在对应资源启用时创建，避免悬空维度。CloudTrail 开启多区域、全局事件和日志完整性验证；Config 提供 Recorder、Delivery Channel 和禁止 S3 公开读取规则；审计 Bucket 版本化、加密并阻止公开访问。Backup Vault Lock 未默认启用，因为错误配置可能形成不可逆保留。

Config、GuardDuty、Backup 与部分 CloudWatch 指标会持续计费，dev 默认关闭。若账号由 AWS Organizations 集中管理这些服务，应关闭本模块对应开关。

