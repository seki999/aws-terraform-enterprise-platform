data "aws_region" "current" {}

resource "aws_ecr_repository" "api" {
  name                 = "${var.name_prefix}-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-api-ecr" })
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain the newest 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.name_prefix}/api"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn
  tags              = merge(var.tags, { Name = "${var.name_prefix}-ecs-logs" })
}

resource "aws_lb" "api" {
  count = var.enable_alb ? 1 : 0

  name                       = substr("${var.name_prefix}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs {
    bucket  = var.access_logs_bucket_name
    prefix  = "alb"
    enabled = true
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb" })
}

resource "aws_lb_target_group" "api" {
  count = var.enable_alb ? 1 : 0

  name        = substr("${var.name_prefix}-api-tg", 0, 32)
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-api-tg" })
}

resource "aws_lb_listener" "http" {
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.api[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[0].arn
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-ecs-cluster" })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.ecs_cpu)
  memory                   = tostring(var.ecs_memory)
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "api"
    image     = coalesce(var.container_image, "${aws_ecr_repository.api.repository_url}:latest")
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]
    environment = [
      { name = "AWS_REGION", value = data.aws_region.current.region },
      { name = "S3_BUCKET_NAME", value = var.upload_bucket_name },
      { name = "DYNAMODB_TABLE_NAME", value = var.dynamodb_table_name },
      { name = "DATABASE_NAME", value = var.database_name },
      { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
      { name = "RDS_HOST", value = coalesce(var.rds_endpoint, "") },
      { name = "REDIS_HOST", value = coalesce(var.redis_endpoint, "") },
    ]
    secrets = [
      { name = "DATABASE_SECRET", valueFrom = var.database_secret_arn },
      { name = "REDIS_AUTH_TOKEN", valueFrom = var.redis_secret_arn },
      { name = "LOG_LEVEL", valueFrom = var.log_level_parameter_arn },
    ]
    healthCheck = {
      command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:${var.container_port}/health')\" || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 20
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "api"
      }
    }
  }])

  tags = merge(var.tags, { Name = "${var.name_prefix}-api-task" })
}

resource "aws_ecs_service" "api" {
  count = var.enable_ecs ? 1 : 0

  name                              = "${var.name_prefix}-api"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.api.arn
  desired_count                     = var.ecs_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60
  enable_execute_command            = true
  wait_for_steady_state             = false

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api[0].arn
    container_name   = "api"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]

    precondition {
      condition     = var.enable_alb
      error_message = "enable_ecs=true 时必须同时 enable_alb=true。"
    }
  }

  depends_on = [aws_lb_listener.http]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-ecs-service" })
}

resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_ecs ? 1 : 0

  max_capacity       = var.ecs_max_count
  min_capacity       = min(var.ecs_desired_count, 1)
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.api[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  count = var.enable_ecs ? 1 : 0

  name               = "${var.name_prefix}-ecs-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 60
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

data "aws_ssm_parameter" "al2023_ami" {
  count = var.enable_ec2 ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "worker" {
  count = var.enable_ec2 ? 1 : 0

  name_prefix   = "${var.name_prefix}-worker-"
  image_id      = data.aws_ssm_parameter.al2023_ami[0].value
  instance_type = var.instance_type
  user_data     = base64encode("#!/bin/bash\ndnf update -y\nsystemctl enable --now amazon-ssm-agent\n")

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_security_group_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-worker" })
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-worker-template" })
}

resource "aws_autoscaling_group" "worker" {
  count = var.enable_ec2 ? 1 : 0

  name                = "${var.name_prefix}-worker-asg"
  vpc_zone_identifier = var.private_app_subnet_ids
  min_size            = 0
  desired_capacity    = 0
  max_size            = 2
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.worker[0].id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
