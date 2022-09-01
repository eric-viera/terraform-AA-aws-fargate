resource "aws_ecs_task_definition" "main" {
  family                   = var.service_name
  network_mode             = var.launch_type == "FARGATE" ? "awsvpc" : "bridge"
  requires_compatibilities = [var.launch_type]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  container_definitions    = var.container_definitions_json
  depends_on = [aws_cloudwatch_log_group.service_log]
}

resource "aws_ecs_service" "main" {
  name                               = "${var.service_name}-service"
  cluster                            = var.cluster
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = var.launch_type
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.strategy

  dynamic "network_configuration" {
    for_each = var.launch_type == "FARGATE" ? [1] : []
    content {
      security_groups  = [aws_security_group.ecs_tasks.id]
      subnets          = var.private_subnets
      assign_public_ip = false
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.service_name}-container"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

}

resource "aws_lb_target_group" "main" {
  name        = "${var.service_name}-tg"
  port        = var.container_port
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id
  target_type = var.launch_type == "FARGATE" ? "ip" : "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = var.health_check_code
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = var.target_group_protocol
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.record.name]
    }
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.service_name}-task-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.container_port
    to_port     = var.container_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = "${var.project_name}-backend-${var.service_name}.${var.domain}"
  type    = "CNAME"
  ttl     = 5
  records = [var.lb_dns_name]
}

resource "aws_cloudwatch_log_group" "service_log" {
  name = "${var.project_name}-${var.service_name}"
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 6
  min_capacity       = 2
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "${aws_ecs_service.main.name}-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  name               = "${aws_ecs_service.main.name}-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80
  }
}