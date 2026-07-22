# 网络设计

## CIDR 规划

默认每个环境使用独立 /16：

| 环境 | VPC | Public | Private App | Private DB |
| --- | --- | --- | --- | --- |
| dev | 10.20.0.0/16 | 10.20.0/24、10.20.1/24 | 10.20.10/24、10.20.11/24 | 10.20.20/24、10.20.21/24 |
| staging | 10.30.0.0/16 | 10.30.0/24、10.30.1/24 | 10.30.10/24、10.30.11/24 | 10.30.20/24、10.30.21/24 |
| prod | 10.40.0.0/16 | 10.40.0/24、10.40.1/24 | 10.40.10/24、10.40.11/24 | 10.40.20/24、10.40.21/24 |

与企业网络互联前必须重新检查 CIDR 重叠。三组列表与 AZ 数量由 Check Block 校验。

## 子网角色

- Public：ALB、NAT Gateway；有到 IGW 的默认路由，但实例不自动分配公网 IP。
- Private Application：ECS、Lambda ENI、可选 EC2；经 NAT 或 Endpoint 出站。
- Private Database：RDS、Redis；没有到 IGW/NAT 的默认路由。

数据库不能放 Public Subnet，因为公网路由扩大攻击面，无法用“未公开”设置替代分层隔离；错误的 SG 或未来配置变更可能直接暴露服务。

## 路由

- Public Route Table：`0.0.0.0/0 -> IGW`。
- 每个 Private App Route Table：可选 `0.0.0.0/0 -> NAT`。
- 每个 Private DB Route Table：只保留 VPC Local 和 Endpoint 路由。
- prod 启用 NAT 时每 AZ 一个，避免跨 AZ 依赖和流量；dev 可单个或关闭。

## Internet Gateway 与 NAT

IGW 只提供 VPC 公网路由能力。NAT 只允许私有子网发起 IPv4 出站，不允许互联网主动连接。NAT 与 EIP 按小时和流量计费，是首要成本风险。

## Security Group

- ALB SG：80/443 入站；只向 VPC 内应用出站。
- App SG：只接受 ALB SG 到容器端口；允许应用所需出站。
- Database SG：只接受 App SG 到 5432。
- Redis SG：只接受 App SG 到 6379。
- Endpoint SG：只接受 App SG 到 443。

生产可进一步把 App SG 出站按目标 SG、Prefix List 与 Endpoint 限制。

## Network ACL

Database Subnet 使用显式 NACL，当前只允许 VPC 内流量。NACL 无状态，修改时必须同时考虑请求、响应和临时端口。SG 是主要细粒度控制，NACL 是额外边界，不重复堆叠复杂规则。

## VPC Endpoint

- Gateway：S3、DynamoDB，无小时费但有路由/Policy 约束。
- Interface：ECR API、ECR DKR、CloudWatch Logs、Secrets Manager，按 AZ 和小时计费。
- ECS 无 NAT 拉取 ECR 镜像时还依赖 S3 Gateway Endpoint。
- Endpoint 默认关闭；启用后验证 Private DNS、SG、Route Table 和执行 Role。

## DNS

VPC 开启 DNS Support 与 DNS Hostnames。Route 53 自定义域名可选。Interface Endpoint 使用 Private DNS，让标准 AWS 服务域名解析到私网 ENI。

## 东西向与南北向

- 南北向：互联网到 CloudFront/ALB/API Gateway，或私有工作负载通过 NAT 出站。
- 东西向：ECS 到 RDS/Redis、Lambda 到数据/消息服务、工作负载到 Endpoint。
- Flow Logs 记录 ACCEPT/REJECT 元数据，不能替代应用访问日志或数据包抓取。

## 验证清单

- 每环境至少 2 个 AZ、每类至少 2 个 Subnet。
- Database Route Table 没有 IGW/NAT 默认路由。
- ECS 不分配 Public IP；RDS 明确不公开。
- SG 使用 SG 引用而不是数据库公网 CIDR。
- prod 启用 NAT 时 NAT 数量等于 AZ 数。
- 无 NAT 场景验证 ECR API/DKR、S3、Logs、Secrets Manager Endpoint。

