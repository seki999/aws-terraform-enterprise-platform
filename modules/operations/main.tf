data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  audit_bucket  = "${var.name_prefix}-audit-${var.bucket_suffix}"
  alarm_actions = [aws_sns_topic.alarms.arn]
}

resource "aws_sns_topic" "alarms" {
  name              = "${var.name_prefix}-alarms"
  kms_master_key_id = var.kms_key_arn
  tags              = merge(var.tags, { Name = "${var.name_prefix}-alarms" })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email == null ? 0 : 1

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_dashboard" "platform" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_name = "${var.name_prefix}-platform"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# ${var.name_prefix}\nOperational overview; alarms are sent to the encrypted SNS topic."
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          region = data.aws_region.current.region
          title  = "ECS CPU and Memory"
          metrics = var.ecs_service_name == null ? [] : [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.enable_monitoring && var.alb_arn_suffix != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-5xx"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-alb-5xx" })
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  count = var.enable_monitoring && var.ecs_service_name != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-cpu"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-ecs-cpu" })
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  count = var.enable_monitoring && var.ecs_service_name != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-memory"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-ecs-memory" })
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks" {
  count = var.enable_monitoring && var.ecs_service_name != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-running-tasks"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-ecs-running-tasks" })
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.enable_monitoring ? var.lambda_function_names : {}

  alarm_name          = "${var.name_prefix}-${each.key}-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = each.value }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-${each.key}-errors" })
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = var.enable_monitoring ? var.lambda_function_names : {}

  alarm_name          = "${var.name_prefix}-${each.key}-throttles"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = each.value }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-${each.key}-throttles" })
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  count = var.enable_monitoring && var.api_id != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-api-5xx"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { ApiId = var.api_id, Stage = "$default" }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-api-5xx" })
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  count = var.enable_monitoring && var.queue_name != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-queue-depth"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 100
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { QueueName = var.queue_name }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-queue-depth" })
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = var.enable_monitoring && var.dlq_name != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-dlq-messages"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { QueueName = var.dlq_name }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-dlq-messages" })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.enable_monitoring && var.rds_identifier != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-cpu"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-rds-cpu" })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  count = var.enable_monitoring && var.rds_identifier != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-free-storage"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2147483648
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-rds-free-storage" })
}

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  count = var.enable_monitoring && var.redis_replication_group_id != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-redis-cpu"
  namespace           = "AWS/ElastiCache"
  metric_name         = "EngineCPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { ReplicationGroupId = var.redis_replication_group_id }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-redis-cpu" })
}

resource "aws_cloudwatch_metric_alarm" "nat_errors" {
  for_each = var.enable_monitoring ? toset(var.nat_gateway_ids) : toset([])

  alarm_name          = "${var.name_prefix}-${each.value}-port-errors"
  namespace           = "AWS/NATGateway"
  metric_name         = "ErrorPortAllocation"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { NatGatewayId = each.value }
  alarm_actions       = local.alarm_actions
  tags                = merge(var.tags, { Name = "${var.name_prefix}-nat-errors" })
}

resource "aws_s3_bucket" "audit" {
  count = var.enable_cloudtrail || var.enable_config ? 1 : 0

  bucket        = local.audit_bucket
  force_destroy = false
  tags          = merge(var.tags, { Name = "${var.name_prefix}-audit" })
}

resource "aws_s3_bucket_public_access_block" "audit" {
  count = var.enable_cloudtrail || var.enable_config ? 1 : 0

  bucket                  = aws_s3_bucket.audit[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit" {
  count = var.enable_cloudtrail || var.enable_config ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  count = var.enable_cloudtrail || var.enable_config ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "audit" {
  count = var.enable_cloudtrail || var.enable_config ? 1 : 0

  statement {
    sid       = "CloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit[0].arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-trail"]
    }
  }

  statement {
    sid       = "CloudTrailWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit[0].arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-trail"]
    }
  }

  statement {
    sid       = "ConfigAclCheck"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.audit[0].arn]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "ConfigWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit[0].arn}/config/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.audit[0].arn,
      "${aws_s3_bucket.audit[0].arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  count = var.enable_cloudtrail || var.enable_config ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id
  policy = data.aws_iam_policy_document.audit[0].json
}

resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.audit[0].id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  tags                          = merge(var.tags, { Name = "${var.name_prefix}-trail" })

  depends_on = [aws_s3_bucket_policy.audit]
}

data "aws_iam_policy_document" "config_assume" {
  count = var.enable_config ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name               = "${var.name_prefix}-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-config-role" })
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "config_bucket" {
  count = var.enable_config ? 1 : 0

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit[0].arn}/config/*"]
  }

  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit[0].arn]
  }
}

resource "aws_iam_role_policy" "config_bucket" {
  count = var.enable_config ? 1 : 0

  name   = "${var.name_prefix}-config-bucket"
  role   = aws_iam_role.config[0].id
  policy = data.aws_iam_policy_document.config_bucket[0].json
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_config ? 1 : 0

  name     = "${var.name_prefix}-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_config ? 1 : 0

  name           = "${var.name_prefix}-delivery"
  s3_bucket_name = aws_s3_bucket.audit[0].id
  s3_key_prefix  = "config"

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }

  depends_on = [aws_s3_bucket_policy.audit]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "s3_public_read" {
  count = var.enable_config ? 1 : 0

  name = "${var.name_prefix}-s3-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-guardduty" })
}

resource "aws_guardduty_detector_feature" "s3" {
  count = var.enable_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

data "aws_iam_policy_document" "backup_assume" {
  count = var.enable_backup ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  count = var.enable_backup ? 1 : 0

  name               = "${var.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-backup-role" })
}

resource "aws_iam_role_policy_attachment" "backup" {
  count = var.enable_backup ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_vault" "this" {
  count = var.enable_backup ? 1 : 0

  name        = "${var.name_prefix}-vault"
  kms_key_arn = var.kms_key_arn
  tags        = merge(var.tags, { Name = "${var.name_prefix}-vault" })
}

resource "aws_backup_plan" "this" {
  count = var.enable_backup ? 1 : 0

  name = "${var.name_prefix}-daily"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = "cron(0 18 ? * * *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-daily-backup" })
}

resource "aws_backup_selection" "this" {
  count = var.enable_backup && length(var.backup_resource_arns) > 0 ? 1 : 0

  name         = "${var.name_prefix}-resources"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.this[0].id
  resources    = var.backup_resource_arns
}
