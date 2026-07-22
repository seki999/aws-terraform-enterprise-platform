data "archive_file" "layer" {
  count = var.enable_serverless ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/../../application/lambda/layer"
  output_path = "${path.module}/layer.zip"
}

data "archive_file" "validator" {
  count = var.enable_serverless ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/../../application/lambda/validator"
  output_path = "${path.module}/validator.zip"
}

data "archive_file" "consumer" {
  count = var.enable_serverless ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/../../application/lambda/consumer"
  output_path = "${path.module}/consumer.zip"
}

data "archive_file" "worker" {
  count = var.enable_serverless ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/../../application/lambda/step-worker"
  output_path = "${path.module}/step-worker.zip"
}

resource "aws_sqs_queue" "dlq" {
  count = var.enable_serverless ? 1 : 0

  name                      = "${var.name_prefix}-jobs-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn
  tags                      = merge(var.tags, { Name = "${var.name_prefix}-jobs-dlq" })
}

resource "aws_sqs_queue" "jobs" {
  count = var.enable_serverless ? 1 : 0

  name                       = "${var.name_prefix}-jobs"
  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = 5
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-jobs" })
}

data "aws_iam_policy_document" "dlq_redrive" {
  count = var.enable_serverless ? 1 : 0

  statement {
    sid       = "AllowSourceQueue"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq[0].arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sqs_queue.jobs[0].arn]
    }
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.enable_serverless ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.jobs[0].arn]
  })
}

resource "aws_sns_topic" "results" {
  count = var.enable_serverless ? 1 : 0

  name              = "${var.name_prefix}-results"
  kms_master_key_id = var.kms_key_arn
  tags              = merge(var.tags, { Name = "${var.name_prefix}-results" })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.enable_serverless && var.sns_notification_email != null ? 1 : 0

  topic_arn = aws_sns_topic.results[0].arn
  protocol  = "email"
  endpoint  = var.sns_notification_email
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.enable_serverless ? toset(["validator", "consumer", "step-worker"]) : toset([])

  name              = "/aws/lambda/${var.name_prefix}-${each.value}"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Name = "${var.name_prefix}-${each.value}-logs" })
}

resource "aws_lambda_layer_version" "common" {
  count = var.enable_serverless ? 1 : 0

  filename            = data.archive_file.layer[0].output_path
  layer_name          = "${var.name_prefix}-common"
  compatible_runtimes = ["python3.13"]
  source_code_hash    = data.archive_file.layer[0].output_base64sha256
  description         = "Shared JSON logging helpers"
}

resource "aws_lambda_function" "validator" {
  count = var.enable_serverless ? 1 : 0

  function_name    = "${var.name_prefix}-validator"
  role             = var.lambda_role_arns["lambda_validator"]
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.validator[0].output_path
  source_code_hash = data.archive_file.validator[0].output_base64sha256
  timeout          = 15
  memory_size      = 256
  layers           = [aws_lambda_layer_version.common[0].arn]
  kms_key_arn      = var.kms_key_arn

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.jobs[0].url
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-validator" })
}

resource "aws_lambda_function" "worker" {
  count = var.enable_serverless ? 1 : 0

  function_name    = "${var.name_prefix}-step-worker"
  role             = var.lambda_role_arns["lambda_worker"]
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.worker[0].output_path
  source_code_hash = data.archive_file.worker[0].output_base64sha256
  timeout          = 60
  memory_size      = 512
  layers           = [aws_lambda_layer_version.common[0].arn]
  kms_key_arn      = var.kms_key_arn

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-step-worker" })
}

data "aws_iam_policy_document" "states_assume" {
  count = var.enable_serverless ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "states" {
  count = var.enable_serverless ? 1 : 0

  name               = "${var.name_prefix}-states-role"
  assume_role_policy = data.aws_iam_policy_document.states_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-states-role" })
}

data "aws_iam_policy_document" "states" {
  count = var.enable_serverless ? 1 : 0

  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.worker[0].arn]
  }

  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.results[0].arn]
  }

  statement {
    actions   = ["logs:CreateLogDelivery", "logs:GetLogDelivery", "logs:UpdateLogDelivery", "logs:DeleteLogDelivery", "logs:ListLogDeliveries", "logs:PutResourcePolicy", "logs:DescribeResourcePolicies", "logs:DescribeLogGroups"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "states" {
  count = var.enable_serverless ? 1 : 0

  name   = "${var.name_prefix}-states"
  role   = aws_iam_role.states[0].id
  policy = data.aws_iam_policy_document.states[0].json
}

resource "aws_cloudwatch_log_group" "states" {
  count = var.enable_serverless ? 1 : 0

  name              = "/aws/vendedlogs/states/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Name = "${var.name_prefix}-states-logs" })
}

resource "aws_sfn_state_machine" "processing" {
  count = var.enable_serverless ? 1 : 0

  name     = "${var.name_prefix}-processing"
  role_arn = aws_iam_role.states[0].arn
  type     = "STANDARD"

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.states[0].arn}:*"
    include_execution_data = false
    level                  = "ERROR"
  }

  definition = jsonencode({
    Comment = "Process a job and notify subscribers"
    StartAt = "ProcessJob"
    States = {
      ProcessJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.worker[0].arn
          "Payload.$"  = "$"
        }
        ResultPath = "$.processing"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2
        }]
        Next = "PublishResult"
      }
      PublishResult = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn    = aws_sns_topic.results[0].arn
          "Message.$" = "States.JsonToString($)"
        }
        End = true
      }
    }
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-processing" })
}

resource "aws_lambda_function" "consumer" {
  count = var.enable_serverless ? 1 : 0

  function_name    = "${var.name_prefix}-consumer"
  role             = var.lambda_role_arns["lambda_consumer"]
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.consumer[0].output_path
  source_code_hash = data.archive_file.consumer[0].output_base64sha256
  timeout          = 30
  memory_size      = 256
  layers           = [aws_lambda_layer_version.common[0].arn]
  kms_key_arn      = var.kms_key_arn

  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.processing[0].arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-consumer" })
}

resource "aws_lambda_event_source_mapping" "jobs" {
  count = var.enable_serverless ? 1 : 0

  event_source_arn                   = aws_sqs_queue.jobs[0].arn
  function_name                      = aws_lambda_function.consumer[0].arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
}

resource "aws_apigatewayv2_api" "jobs" {
  count = var.enable_serverless ? 1 : 0

  name          = "${var.name_prefix}-jobs-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type", "x-correlation-id"]
    allow_methods = ["POST", "OPTIONS"]
    allow_origins = ["*"]
    max_age       = 300
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-jobs-api" })
}

resource "aws_apigatewayv2_integration" "validator" {
  count = var.enable_serverless ? 1 : 0

  api_id                 = aws_apigatewayv2_api.jobs[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.validator[0].invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 15000
}

resource "aws_apigatewayv2_route" "jobs" {
  count = var.enable_serverless ? 1 : 0

  api_id    = aws_apigatewayv2_api.jobs[0].id
  route_key = "POST /jobs"
  target    = "integrations/${aws_apigatewayv2_integration.validator[0].id}"
}

resource "aws_cloudwatch_log_group" "api" {
  count = var.enable_serverless ? 1 : 0

  name              = "/aws/apigateway/${var.name_prefix}-jobs"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Name = "${var.name_prefix}-api-logs" })
}

resource "aws_apigatewayv2_stage" "default" {
  count = var.enable_serverless ? 1 : 0

  api_id      = aws_apigatewayv2_api.jobs[0].id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 50
    throttling_rate_limit    = 25
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-api-stage" })
}

resource "aws_lambda_permission" "api" {
  count = var.enable_serverless ? 1 : 0

  statement_id  = "AllowApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validator[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.jobs[0].execution_arn}/*/*"
}

data "aws_iam_policy_document" "events_assume" {
  count = var.enable_serverless ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events" {
  count = var.enable_serverless ? 1 : 0

  name               = "${var.name_prefix}-events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-events-role" })
}

data "aws_iam_policy_document" "events" {
  count = var.enable_serverless ? 1 : 0

  statement {
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.processing[0].arn]
  }
}

resource "aws_iam_role_policy" "events" {
  count = var.enable_serverless ? 1 : 0

  name   = "${var.name_prefix}-events"
  role   = aws_iam_role.events[0].id
  policy = data.aws_iam_policy_document.events[0].json
}

resource "aws_cloudwatch_event_rule" "daily_health" {
  count = var.enable_serverless ? 1 : 0

  name                = "${var.name_prefix}-daily-health"
  description         = "Daily workflow health event"
  schedule_expression = "rate(1 day)"
  state               = "DISABLED"
  tags                = merge(var.tags, { Name = "${var.name_prefix}-daily-health" })
}

resource "aws_cloudwatch_event_target" "daily_health" {
  count = var.enable_serverless ? 1 : 0

  rule     = aws_cloudwatch_event_rule.daily_health[0].name
  arn      = aws_sfn_state_machine.processing[0].arn
  role_arn = aws_iam_role.events[0].arn
  input    = jsonencode({ job_id = "scheduled-health", created_at = "scheduled", status = "scheduled" })
}

