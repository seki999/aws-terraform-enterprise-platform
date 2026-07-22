# Lambda 示例

- `validator`：验证 API 请求并发送 SQS。
- `consumer`：批量消费 SQS，失败时返回部分批处理失败列表。
- `step-worker`：以条件写幂等更新 DynamoDB。
- `layer`：共享 JSON 日志函数，过滤常见敏感字段名。

```bash
python -m pip install -r application/lambda/requirements-dev.txt
python -m pytest application/lambda/tests
```

