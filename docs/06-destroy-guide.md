# 销毁指南

## 原则

销毁是高风险、不可逆操作。本仓库没有执行任何 Destroy。prod 不允许使用自动包装脚本销毁；必须单独变更、双人审批和数据负责人确认。

## 销毁前

1. 确认账号、Region、环境目录、Backend Key。
2. 冻结 CI 与人工 Apply。
3. `terraform state pull` 到受控加密备份。
4. 导出需要保留的 S3 数据、RDS Snapshot、DynamoDB Backup、Redis Snapshot、ECR Image 和日志。
5. 检查 RDS Deletion Protection、Final Snapshot 名称、Backup Recovery Point 与合规保留。
6. 检查 DNS TTL 和外部消费者。
7. 生成并逐项审查 Destroy Plan。

```bash
terraform plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan
terraform show destroy.tfplan
```

## dev/staging

获得明确授权后可使用：

```bash
make destroy ENV=dev CONFIRM=destroy-dev
```

脚本会再次显示 Plan 并要求输入 `DESTROY`。这只是防误操作，不是审批替代品。

## 建议顺序

1. 停止外部流量和事件入口。
2. 等待 SQS 清空或导出剩余消息；检查 DLQ。
3. 将 ECS desired count 降到 0。
4. 保存数据库/对象/日志。
5. 销毁应用环境。
6. 检查 Terraform 报错并处理保留资源。
7. 检查账单与残留。
8. 仅在所有环境迁移完成后处理 Backend。

不要用 `-target` 强行拆除依赖，除非在故障恢复中有记录的理由；使用后必须完整 Plan。

## 常见阻塞

- S3 Bucket 非空且 `force_destroy=false`：先确认数据保留，再通过受控流程清理。
- RDS Deletion Protection：单独 Plan 关闭，审查后 Apply，再生成 Destroy Plan。
- Final Snapshot 名称冲突：选择新名称或保留现有 Snapshot。
- ENI 正在使用：等待 ECS/Lambda/Endpoint 清理。
- Backup 保留：Recovery Point 可能按策略继续存在并收费。
- CodeStar Connection：可能需要控制台检查。
- KMS Key：进入等待删除状态，不会立即消失。

## 销毁后检查

- Cost Explorer、Billing 与 Budgets；
- NAT Gateway/EIP、ALB、RDS/Redis、EC2/Fargate；
- VPC Endpoint/ENI；
- S3、ECR、Snapshot、Backup Vault；
- CloudWatch Log Group、CloudTrail/Config；
- Route 53 Record/ACM；
- CodeBuild/CodePipeline/Connection；
- State Bucket 与 KMS（应最后保留或迁移）。

记录残留、原因、负责人和预计清理时间。不要把“Terraform 完成”当成“账单为零”。

