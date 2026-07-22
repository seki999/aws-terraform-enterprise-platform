provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "state_key" {
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
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  name_prefix = "${var.project_name}-backend"
  bucket_name = coalesce(var.bucket_name_override, "${local.name_prefix}-${random_id.bucket_suffix.hex}")
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  })
}

resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform remote state for ${var.project_name}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.state_key.json

  tags = {
    Name = "${local.name_prefix}-kms"
  }
}

resource "aws_kms_alias" "state" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_18:The backend bucket cannot log to itself; production should use a separate central log account.
  #checkov:skip=CKV_AWS_144:Cross-region replication requires a separately governed DR region and key.
  #checkov:skip=CKV2_AWS_62:Terraform state has no event-driven consumer and must not emit object notifications.
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.name_prefix}-state"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.bucket.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStatePrefix"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["states/*"]
    }
  }

  statement {
    sid       = "ReadWriteState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.state.arn}/states/*/terraform.tfstate"]
  }

  statement {
    sid       = "ManageStateLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/states/*/terraform.tfstate.tflock"]
  }

  statement {
    sid       = "UseStateKey"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [aws_kms_key.state.arn]
  }
}
