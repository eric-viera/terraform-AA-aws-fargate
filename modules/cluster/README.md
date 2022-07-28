# ECS Cluster
Module to provision an ECS cluster, an IAM task role, and an IAM task execution role in AWS
- A cluster is a logical grouping of tasks.
- An execution task role is the role ECS assumes to provision the container and bring the task online.
- A task role is the role ECS assumes to perform any action needed by the task while it is running.

This module enables you to assign custom or managed policies to the task role, and the task execution role, in order to grant your tasks any privileges it needs to perform its functions.

## Input Variables
| Variable                           | Defaut Value | Type         | Description                                       |
|:---------------------------------- |:------------ |:------------ |:------------------------------------------------- |
| project_name                       |              | string       | Self-explanatory                                  |
| additional_role_policies           |              | list(string) | List of json strings containing policy statements |
| additional_execution_role_policies |              | list(string) | List of json strings containing policy statements |

## Resources Created
- aws_ecs_cluster.main

- aws_iam_role.ecs_task_role
- aws_iam_policy.additional-task-policies
- aws_iam_role_policy_attachment.task_policy_attachments

- aws_iam_role.ecs_execution_role
- aws_iam_policy.additional-execution-policies
- aws_iam_role_policy_attachment.execution_policy_attachments
- aws_iam_role_policy_attachment.ecs-task-execution-role-policy-attachment


## Output
| Output                  | Value                               | Type   | Description      |
|:----------------------- |:----------------------------------- |:------ |:---------------- |
| task_role_arn           | aws_iam_role.ecs_task_role.arn      | string | Self-explanatory |
| task_execution_role_arn | aws_iam_role.ecs_execution_role.arn | string | Self-explanatory |
| cluster_id              | aws_ecs_cluster.main.id             | string | Self-explanatory |
| cluster_name            | aws_ecs_cluster.main.name           | string | Self-explanatory |