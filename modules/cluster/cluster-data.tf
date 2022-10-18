data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "ecs_agent_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_ami" "ec2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_acm_certificate" "certificate" {
count = var.listener_protocol == "HTTPS" ? 1 : 0

  domain   = "*.${var.domain}"
  statuses = ["ISSUED"]
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "topic-policy" {
  statement {
    actions = [ "SNS:Publish" ]
    effect = "Allow"
    resources = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_ecs_cluster.main.name}-service-down-topic"]
    principals {
      type = "Service"
      identifiers = [ "cloudwatch.amazonaws.com" ]
    }
  }
}
