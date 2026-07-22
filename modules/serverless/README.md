# Serverless 模块

实现真实异步链路：

1. API Gateway `POST /jobs` 调用 Validator Lambda；
2. Validator 校验请求并发送到加密 SQS；
3. Consumer Lambda 由 SQS 触发并启动 Step Functions；
4. State Machine 调用 Worker Lambda，Worker 幂等写入 DynamoDB；
5. State Machine 通过 SNS 发布结果；
6. 失败消息按 Redrive Policy 进入加密 DLQ；
7. EventBridge 提供默认禁用的定时入口。

三个 Lambda 使用独立 IAM Role，并共享最小 Layer。源代码在 `application/lambda`，Terraform 使用 Archive Provider 构建 Zip。Serverless 默认关闭；启用前先运行 Python 测试并确认 SNS 邮件订阅。

