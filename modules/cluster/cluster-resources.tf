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
  max_size = 4
  min_size = 1
  desired_capacity = 2
  name_prefix = var.project_name
  protect_from_scale_in = true
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
    managed_termination_protection = "ENABLED"
    
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 2
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "providers" {
  cluster_name = aws_ecs_cluster.main.name
  capacity_providers = [ "FARGATE", aws_ecs_capacity_provider.ecs_ec2_capacity.name ]
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