data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [ "sts:AssumeRole" ]
    effect = "Allow"
    principals {
      identifiers = [ "ecs-tasks.amazonaws.com" ]
      type = "Service"
    }
  }
}
