data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket        = "${var.name_prefix}-artifacts-${var.bucket_suffix}"
  force_destroy = false
  tags          = merge(var.tags, { Name = "${var.name_prefix}-artifacts" })
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket                  = aws_s3_bucket.artifacts[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "expire-artifacts"
    status = "Enabled"
    filter {}
    expiration { days = 30 }
  }
}

resource "aws_codestarconnections_connection" "github" {
  count = var.enable_cicd ? 1 : 0

  name          = "${var.name_prefix}-github"
  provider_type = "GitHub"
  tags          = merge(var.tags, { Name = "${var.name_prefix}-github-connection" })

  lifecycle {
    precondition {
      condition     = var.github_repository != null
      error_message = "enable_cicd=true 时必须提供 github_repository。"
    }
  }
}

data "aws_iam_policy_document" "codebuild_assume" {
  count = var.enable_cicd ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  count = var.enable_cicd ? 1 : 0

  name               = "${var.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-codebuild-role" })
}

data "aws_iam_policy_document" "codebuild" {
  count = var.enable_cicd ? 1 : 0

  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name_prefix}*:*"]
  }

  statement {
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["${aws_s3_bucket.artifacts[0].arn}/*"]
  }

  statement {
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  count = var.enable_cicd ? 1 : 0

  name   = "${var.name_prefix}-codebuild"
  role   = aws_iam_role.codebuild[0].id
  policy = data.aws_iam_policy_document.codebuild[0].json
}

resource "aws_codebuild_project" "terraform" {
  count = var.enable_cicd ? 1 : 0

  name          = "${var.name_prefix}-terraform-check"
  service_role  = aws_iam_role.codebuild[0].arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.15.8"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_IN_AUTOMATION"
      value = "true"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.name_prefix}"
      stream_name = "terraform"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-terraform-check" })
}

data "aws_iam_policy_document" "pipeline_assume" {
  count = var.enable_cicd ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  count = var.enable_cicd ? 1 : 0

  name               = "${var.name_prefix}-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-pipeline-role" })
}

data "aws_iam_policy_document" "pipeline" {
  count = var.enable_cicd ? 1 : 0

  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github[0].arn]
  }

  statement {
    actions   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
    resources = [aws_codebuild_project.terraform[0].arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:GetBucketVersioning"]
    resources = [aws_s3_bucket.artifacts[0].arn, "${aws_s3_bucket.artifacts[0].arn}/*"]
  }

  statement {
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  count = var.enable_cicd ? 1 : 0

  name   = "${var.name_prefix}-pipeline"
  role   = aws_iam_role.pipeline[0].id
  policy = data.aws_iam_policy_document.pipeline[0].json
}

resource "aws_codepipeline" "this" {
  count = var.enable_cicd ? 1 : 0

  name     = "${var.name_prefix}-pipeline"
  role_arn = aws_iam_role.pipeline[0].arn

  artifact_store {
    location = aws_s3_bucket.artifacts[0].id
    type     = "S3"

    encryption_key {
      id   = var.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github[0].arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Validate"

    action {
      name             = "TerraformCheck"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["validated"]

      configuration = {
        ProjectName = aws_codebuild_project.terraform[0].name
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-pipeline" })
}

