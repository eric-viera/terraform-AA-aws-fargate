data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "flow_log_assume_policy" {
  statement {
    actions = [ "sts:AssumeRole" ]
    effect = "Allow"
    principals {
      identifiers = [ "vpc-flow-logs.amazonaws.com" ]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "flow_log_policy" {
  statement {
    actions = [ 
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams" 
    ]
    effect = "Allow"
    resources = [ "*" ]
  }
}

data "aws_region" "current" {}
