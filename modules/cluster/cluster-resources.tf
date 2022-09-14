resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-${var.environment}-TaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.project_name}-${var.environment}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "additional-task-policies" {
  name        = "${var.project_name}-${var.environment}-task-role-policies"
  description = "additional policies needed by the task role"
  count       = length(var.additional_role_policies)
  policy      = element(var.additional_role_policies, count.index)
}

resource "aws_iam_role_policy_attachment" "task_policy_attachments" {
  role       = aws_iam_role.ecs_task_role.name
  count      = length(var.additional_role_policies)
  policy_arn = element(aws_iam_policy.additional-task-policies[*].arn, count.index)
}

resource "aws_iam_policy" "additional-execution-policies" {
  name        = "${var.project_name}-${var.environment}-execution-role-policies"
  description = "additional policies needed by the execution role"
  count       = length(var.additional_execution_role_policies)
  policy      = element(var.additional_execution_role_policies, count.index)
}

resource "aws_iam_role_policy_attachment" "execution_policy_attachments" {
  role       = aws_iam_role.ecs_execution_role.name
  count      = length(var.additional_execution_role_policies)
  policy_arn = element(aws_iam_policy.additional-execution-policies[*].arn, count.index)
}

resource "aws_iam_role" "ecs_agent" {
  name               = "${var.project_name}-${var.environment}-ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "${var.project_name}-${var.environment}-ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

}

resource "aws_launch_configuration" "launch_conf" {
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  image_id             = data.aws_ami.ec2_ami.id
  instance_type        = "t3a.medium"
  name_prefix          = "${var.project_name}-${var.environment}"
  security_groups      = setunion([aws_security_group.ec2.id], var.added_sgs)
  user_data            = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster_asg" {
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.launch_conf.name
  max_size             = 10
  min_size             = 1
  desired_capacity     = 2
  name_prefix          = "${var.project_name}-${var.environment}"
  vpc_zone_identifier  = var.private_subnets

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "ecs_ec2_capacity" {
  name = "${var.project_name}-${var.environment}-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster_asg.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "providers" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", aws_ecs_capacity_provider.ecs_ec2_capacity.name]
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = var.listener_port
  protocol          = var.listener_protocol
  certificate_arn   = var.listener_protocol == "HTTPS" ? data.aws_acm_certificate.certificate[0].arn : null
  ssl_policy        = var.listener_protocol == "HTTPS" ? "ELBSecurityPolicy-2016-08" : null

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.project_name}-${var.environment}-sg-alb"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = var.listener_port
    to_port          = var.listener_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ec2" {
  name   = "${var.project_name}-${var.environment}-sg-ec2"
  vpc_id = var.vpc_id

  ingress {
    protocol  = "tcp"
    from_port = 32768
    to_port   = 65535
    security_groups = [ aws_security_group.alb.id ]
    # cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_wafv2_web_acl" "lb_waf" {
  name        = "${aws_lb.main.name}-waf"
  description = "Uses AWS managed rulesets."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS_CommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["CN", "US", "TR", "BR", "IN", "MY", "ID", "RU", "DE", "UA", "ES"]
            /* As of march 2022, according to Cloudflare, the top 10 sources of DDoS attacks are:
              1.China
              2.U.S.
              3.Brazil
              4.India
              5.Malaysia
              6.Indonesia
              7.Russia
              8.Germany
              9.Ukraine
             10.Spain
            Source: https://www.govtech.com/security/here-are-the-top-10-countries-where-ddos-attacks-originate */
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSCommonRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_LinuxRules"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSLinuxRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_BadInputsRules"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSBadInputsRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_AdminProtectionRules"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSAdminProtectionRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_UnixRules"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSUnixRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_IpReputationRules"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSIpReputationRules-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS_AnonymousIpRules"
    priority = 7

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${aws_lb.main.name}-AWSAnonymousIpRules-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${aws_lb.main.name}-waf-metric"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "waf_assoc" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.lb_waf.arn

  depends_on = [time_sleep.wait_for_waf]
}

resource "time_sleep" "wait_for_waf" {
  depends_on = [aws_wafv2_web_acl.lb_waf]

  create_duration = "3m"
}
