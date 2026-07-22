data "aws_iam_policy_document" "rds_monitoring_assume" {
  count = var.enable_rds && var.enable_enhanced_monitoring ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

data "aws_partition" "current" {}

resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_rds && var.enable_enhanced_monitoring ? 1 : 0

  name               = "${var.name_prefix}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume[0].json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-rds-monitoring-role" })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_rds && var.enable_enhanced_monitoring ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_subnet_group" "this" {
  count = var.enable_rds ? 1 : 0

  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-db-subnets" })
}

resource "aws_db_parameter_group" "postgres" {
  count = var.enable_rds ? 1 : 0

  name   = "${var.name_prefix}-postgres17"
  family = "postgres17"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-postgres17" })
}

resource "aws_db_instance" "postgres" {
  count = var.enable_rds ? 1 : 0

  identifier                      = "${var.name_prefix}-postgres"
  engine                          = "postgres"
  engine_version                  = "17"
  instance_class                  = var.rds_instance_class
  allocated_storage               = 20
  max_allocated_storage           = 100
  storage_type                    = "gp3"
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn
  db_name                         = var.database_name
  username                        = var.database_username
  password                        = var.database_password
  port                            = 5432
  db_subnet_group_name            = aws_db_subnet_group.this[0].name
  vpc_security_group_ids          = [var.database_security_group_id]
  publicly_accessible             = false
  multi_az                        = var.enable_rds_multi_az
  backup_retention_period         = var.backup_retention_days
  backup_window                   = "18:00-19:00"
  maintenance_window              = "sun:19:30-sun:20:30"
  parameter_group_name            = aws_db_parameter_group.postgres[0].name
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = var.enable_enhanced_monitoring ? 60 : 0
  monitoring_role_arn             = var.enable_enhanced_monitoring ? aws_iam_role.rds_monitoring[0].arn : null
  performance_insights_enabled    = var.enable_performance_insights
  performance_insights_kms_key_id = var.enable_performance_insights ? var.kms_key_arn : null
  deletion_protection             = var.enable_deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : "${var.name_prefix}-postgres-final"
  auto_minor_version_upgrade      = true
  copy_tags_to_snapshot           = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-postgres" })
}

resource "aws_dynamodb_table" "jobs" {
  name         = "${var.name_prefix}-jobs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"
  range_key    = "created_at"

  attribute {
    name = "job_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "status-created-at-index"
    projection_type = "ALL"

    key_schema {
      attribute_name = "status"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "created_at"
      key_type       = "RANGE"
    }
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  stream_enabled   = var.enable_dynamodb_stream
  stream_view_type = var.enable_dynamodb_stream ? "NEW_AND_OLD_IMAGES" : null

  tags = merge(var.tags, { Name = "${var.name_prefix}-jobs" })
}

resource "aws_elasticache_subnet_group" "redis" {
  count = var.enable_redis ? 1 : 0

  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = var.private_db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-redis-subnets" })
}

resource "aws_elasticache_parameter_group" "redis" {
  count = var.enable_redis ? 1 : 0

  name   = "${var.name_prefix}-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-redis7" })
}

resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_redis ? 1 : 0

  replication_group_id       = substr("${var.name_prefix}-redis", 0, 40)
  description                = "Private encrypted Redis for ${var.name_prefix}"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = var.redis_node_type
  port                       = 6379
  num_cache_clusters         = var.redis_multi_az ? 2 : 1
  parameter_group_name       = aws_elasticache_parameter_group.redis[0].name
  subnet_group_name          = aws_elasticache_subnet_group.redis[0].name
  security_group_ids         = [var.redis_security_group_id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  kms_key_id                 = var.kms_key_arn
  automatic_failover_enabled = var.redis_multi_az
  multi_az_enabled           = var.redis_multi_az
  apply_immediately          = false
  snapshot_retention_limit   = var.redis_multi_az ? 7 : 1

  tags = merge(var.tags, { Name = "${var.name_prefix}-redis" })
}
