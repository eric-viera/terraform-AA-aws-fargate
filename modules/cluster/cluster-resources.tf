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
