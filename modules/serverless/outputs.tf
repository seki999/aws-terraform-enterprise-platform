output "api_endpoint" {
  description = "API Gateway HTTP API Endpoint；未启用时为 null。"
  value       = try(aws_apigatewayv2_api.jobs[0].api_endpoint, null)
}

output "api_id" {
  description = "API Gateway API ID；未启用时为 null。"
  value       = try(aws_apigatewayv2_api.jobs[0].id, null)
}

output "queue_url" {
  description = "Jobs SQS Queue URL；未启用时为空字符串。"
  value       = try(aws_sqs_queue.jobs[0].url, "")
}

output "queue_name" {
  description = "Jobs SQS Queue 名称；未启用时为 null。"
  value       = try(aws_sqs_queue.jobs[0].name, null)
}

output "dlq_name" {
  description = "DLQ 名称；未启用时为 null。"
  value       = try(aws_sqs_queue.dlq[0].name, null)
}

output "sns_topic_arn" {
  description = "结果 SNS Topic ARN；未启用时为 null。"
  value       = try(aws_sns_topic.results[0].arn, null)
}

output "state_machine_arn" {
  description = "Step Functions State Machine ARN；未启用时为 null。"
  value       = try(aws_sfn_state_machine.processing[0].arn, null)
}

output "lambda_function_names" {
  description = "Lambda Function 名称；未启用时为空 Map。"
  value = var.enable_serverless ? {
    validator = aws_lambda_function.validator[0].function_name
    consumer  = aws_lambda_function.consumer[0].function_name
    worker    = aws_lambda_function.worker[0].function_name
  } : {}
}

