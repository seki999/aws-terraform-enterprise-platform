# Platform 组合模块

该模块连接 Networking、Identity、Frontend、Data、Serverless、Compute、Operations 和 CI/CD 模块。环境根模块只传入环境差异和两个 AWS Provider（东京与弗吉尼亚北部）。

模块包含跨变量检查：三组 Subnet CIDR 数量必须与 AZ 一致；prod 必须每 AZ 一个 NAT，且启用 RDS 时必须 Multi-AZ。高成本资源全部由显式开关控制。

