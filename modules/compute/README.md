# Compute 模块

创建 ECR、ECS Cluster、Fargate Task/Service、ALB、Target Group、Listener、ECS Auto Scaling、CloudWatch Logs，以及默认关闭的 EC2 Launch Template/ASG。

ECS Task 固定运行在 Private Application Subnet 且不分配公网 IP；ALB 位于至少两个 Public Subnet。应用镜像必须在启用 ECS 前推送到 ECR，否则 Service 无法稳定运行。EC2 示例不开放 SSH，强制 IMDSv2，并使用 SSM Instance Profile。

ALB、Fargate、EC2 都可能持续计费，dev 示例默认关闭。

