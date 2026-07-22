# Networking 模块

创建跨 2-3 AZ 的 VPC、三层子网、IGW、可选 NAT、独立 Route Table、Database NACL、应用安全组、VPC Endpoint 和 Flow Logs。

数据库子网没有到 IGW/NAT 的默认路由。Security Group 是主要有状态控制，NACL 只提供子网级基线。dev 可关闭或共享 NAT；prod 应每 AZ 一个 NAT。

## 关键输入

`availability_zones` 和三组 Subnet CIDR 必须长度一致。根模块负责这项跨变量校验。Interface Endpoint 按 AZ 持续收费，应显式开启。

