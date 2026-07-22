# CI/CD 模块

创建加密 Artifact Bucket、CodeBuild、CodePipeline 和 GitHub CodeStar Connection。默认关闭，以避免固定成本和未经授权的外部连接。

CodeStar Connection 创建后处于 Pending，必须由用户在 AWS 控制台完成 GitHub 授权；Terraform 不能代替该人工授权。Pipeline 仅做静态验证，不自动 Apply。主要 PR 质量门由 GitHub Actions 和 OIDC 承担。

