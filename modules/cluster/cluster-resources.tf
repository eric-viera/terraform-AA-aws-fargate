resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-TaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "additional-task-policies" {
  name        = "${var.project_name}-task-role-policies"
  description = "additional policies needed by the task role"
  count       = length(var.additional_role_policies)
  policy      = element(var.additional_role_policies, count.index)
}

resource "aws_iam_role_policy_attachment" "task_policy_attachments" {
  role = aws_iam_role.ecs_task_role.name
  count = length(var.additional_role_policies)
  policy_arn = element(aws_iam_policy.additional-task-policies[*].arn, count.index)
}

resource "aws_iam_policy" "additional-execution-policies" {
  name        = "${var.project_name}-execution-role-policies"
  description = "additional policies needed by the execution role"
  count       = length(var.additional_execution_role_policies)
  policy      = element(var.additional_execution_role_policies, count.index)
}

resource "aws_iam_role_policy_attachment" "execution_policy_attachments" {
  role = aws_iam_role.ecs_execution_role.name
  count = length(var.additional_execution_role_policies)
  policy_arn = element(aws_iam_policy.additional-execution-policies[*].arn, count.index)
}

resource "aws_iam_role" "ecs_agent" {
  name               = "${var.project_name}-ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "${var.project_name}-ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = {
    "cost-tag" = var.project_name
  }
}

resource "aws_launch_configuration" "launch_conf" {
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  image_id = data.aws_ami.ec2_ami.id
  instance_type = "t3a.medium"
  name_prefix = var.project_name
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster_asg" {
  health_check_type = "EC2"
  launch_configuration = aws_launch_configuration.launch_conf.name
  max_size = 10
  min_size = 1
  desired_capacity = 2
  name_prefix = var.project_name
  vpc_zone_identifier = var.private_subnets
  
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "ecs_ec2_capacity" {
  name = "${var.project_name}-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster_asg.arn
    
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "providers" {
  cluster_name = aws_ecs_cluster.main.name
  capacity_providers = [ "FARGATE", aws_ecs_capacity_provider.ecs_ec2_capacity.name ]
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = var.listener_port
  protocol          = var.listener_protocol

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
  name   = "${var.project_name}-sg-alb"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 0
    to_port          = 65535
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 65535
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
