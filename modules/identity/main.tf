data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  roles = {
    ecs_execution    = "ecs-tasks.amazonaws.com"
    ecs_task         = "ecs-tasks.amazonaws.com"
    lambda_validator = "lambda.amazonaws.com"
    lambda_consumer  = "lambda.amazonaws.com"
    lambda_worker    = "lambda.amazonaws.com"
    ec2              = "ec2.amazonaws.com"
  }
}

data "aws_iam_policy_document" "data_key" {
  #checkov:skip=CKV_AWS_109:The wildcard applies only to the account root principal in the standard KMS IAM-delegation statement.
  #checkov:skip=CKV_AWS_111:The wildcard applies only to the account root principal in the standard KMS IAM-delegation statement.
  #checkov:skip=CKV_AWS_356:KMS key policies require Resource star because the policy is attached to the key itself.
  statement {
    sid       = "EnableIamUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "logs_key" {
  #checkov:skip=CKV_AWS_109:Wildcard actions are limited to account root; the Logs service statement is separately scoped by service and encryption context.
  #checkov:skip=CKV_AWS_111:Wildcard write actions are limited to account root in the standard KMS IAM-delegation statement.
  #checkov:skip=CKV_AWS_356:KMS key policies require Resource star; principals and the Logs encryption context provide the boundary.
  statement {
    sid       = "EnableIamUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudWatchLogs"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:*"]
    }
  }
}

resource "aws_kms_key" "data" {
  description         = "Application data encryption for ${var.name_prefix}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.data_key.json
  tags                = merge(var.tags, { Name = "${var.name_prefix}-data-kms" })
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.name_prefix}-data"
  target_key_id = aws_kms_key.data.key_id
}

resource "aws_kms_key" "logs" {
  description         = "Log encryption for ${var.name_prefix}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.logs_key.json
  tags                = merge(var.tags, { Name = "${var.name_prefix}-logs-kms" })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.name_prefix}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

resource "random_password" "database" {
  length           = 32
  special          = true
  override_special = "!#$%&*+-.:=?@^_"
}

resource "random_password" "redis" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "database" {
  #checkov:skip=CKV2_AWS_57:Rotation requires an application-specific Lambda and dual-credential rollout; see docs/03-security-design.md.
  name                    = "${var.name_prefix}/database"
  description             = "PostgreSQL credentials for ${var.name_prefix}"
  kms_key_id              = aws_kms_key.data.arn
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-database-secret" })
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = "platform_admin"
    password = random_password.database.result
  })
}

resource "aws_secretsmanager_secret" "redis" {
  #checkov:skip=CKV2_AWS_57:Rotation requires coordinated Redis token replacement; see docs/03-security-design.md.
  name                    = "${var.name_prefix}/redis"
  description             = "Redis auth token for ${var.name_prefix}"
  kms_key_id              = aws_kms_key.data.arn
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-redis-secret" })
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = random_password.redis.result
}

resource "aws_ssm_parameter" "log_level" {
  name        = "/${var.name_prefix}/app/log-level"
  description = "Non-sensitive application log level"
  type        = "SecureString"
  key_id      = aws_kms_key.data.arn
  value       = "INFO"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-log-level" })
}

data "aws_iam_policy_document" "assume" {
  for_each = local.roles

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [each.value]
    }
  }
}

resource "aws_iam_role" "runtime" {
  for_each = local.roles

  name               = "${var.name_prefix}-${replace(each.key, "_", "-")}-role"
  assume_role_policy = data.aws_iam_policy_document.assume[each.key].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-${replace(each.key, "_", "-")}-role" })
}

data "aws_iam_policy_document" "ecs_execution" {
  statement {
    sid       = "ECRAuthorization"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullImages"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["arn:${local.partition}:ecr:${local.region}:${local.account_id}:repository/${var.name_prefix}-*"]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/ecs/${var.name_prefix}*:*"]
  }

  statement {
    sid     = "ReadRuntimeConfiguration"
    actions = ["secretsmanager:GetSecretValue", "ssm:GetParameters"]
    resources = [
      aws_secretsmanager_secret.database.arn,
      aws_secretsmanager_secret.redis.arn,
      aws_ssm_parameter.log_level.arn,
    ]
  }

  statement {
    sid       = "DecryptRuntimeConfiguration"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.data.arn]
  }
}

resource "aws_iam_role_policy" "ecs_execution" {
  name   = "${var.name_prefix}-ecs-execution"
  role   = aws_iam_role.runtime["ecs_execution"].id
  policy = data.aws_iam_policy_document.ecs_execution.json
}

data "aws_iam_policy_document" "application" {
  statement {
    sid = "ApplicationData"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "s3:GetObject",
      "s3:PutObject",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:SendMessage",
    ]
    resources = [
      "arn:${local.partition}:dynamodb:${local.region}:${local.account_id}:table/${var.name_prefix}-*",
      "arn:${local.partition}:s3:::*${var.name_prefix}*/*",
      "arn:${local.partition}:sqs:${local.region}:${local.account_id}:${var.name_prefix}-*",
    ]
  }

  statement {
    sid       = "StartWorkflow"
    actions   = ["states:StartExecution"]
    resources = ["arn:${local.partition}:states:${local.region}:${local.account_id}:stateMachine:${var.name_prefix}-*"]
  }

  statement {
    sid       = "PublishResults"
    actions   = ["sns:Publish"]
    resources = ["arn:${local.partition}:sns:${local.region}:${local.account_id}:${var.name_prefix}-*"]
  }

  statement {
    sid       = "DecryptApplicationData"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.data.arn]
  }

  statement {
    sid       = "WriteApplicationLogs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/*/${var.name_prefix}*:*"]
  }
}

resource "aws_iam_role_policy" "ecs_task" {
  name   = "${var.name_prefix}-ecs-task"
  role   = aws_iam_role.runtime["ecs_task"].id
  policy = data.aws_iam_policy_document.application.json
}

resource "aws_iam_role_policy" "lambda" {
  for_each = toset(["lambda_validator", "lambda_consumer", "lambda_worker"])

  name   = "${var.name_prefix}-${replace(each.value, "_", "-")}"
  role   = aws_iam_role.runtime[each.value].id
  policy = data.aws_iam_policy_document.application.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.runtime["ec2"].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.runtime["ec2"].name
  tags = merge(var.tags, { Name = "${var.name_prefix}-ec2-profile" })
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = merge(var.tags, { Name = "${var.name_prefix}-github-oidc" })
}

data "aws_iam_policy_document" "github_assume" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for subject in var.github_subjects : "repo:${var.github_repository}:${subject}"]
    }
  }
}

resource "aws_iam_role" "github_plan" {
  count = var.enable_github_oidc ? 1 : 0

  name               = "${var.name_prefix}-github-plan-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-github-plan-role" })

  lifecycle {
    precondition {
      condition     = var.github_repository != null
      error_message = "enable_github_oidc=true 时必须提供 github_repository。"
    }
  }
}
