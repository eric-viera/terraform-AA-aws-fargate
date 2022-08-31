# ECS Cluster
Module to provision an ECS cluster, a load balancer with a listener, an IAM task role, and an IAM task execution role in AWS
- A cluster is a logical grouping of tasks.
- An execution task role is the role ECS assumes to provision the container and bring the task online.
- A task role is the role ECS assumes to perform any action needed by the task while it is running.

This module enables you to assign custom or managed policies to the task role, and the task execution role, in order to grant your tasks any privileges it needs to perform its functions.

This module assumes that if you want an HTTPS listener you already have an *.&lt;domain&gt; acl certificate and can provide the domain for that certificate

## Input Variables
| Variable                           | Defaut Value | Type         | Description                                       |
|:---------------------------------- |:------------ |:------------ |:------------------------------------------------- |
| project_name                       |              | string       | Self-explanatory                                  |
| additional_role_policies           |              | list(string) | List of json strings containing policy statements |
| additional_execution_role_policies |              | list(string) | List of json strings containing policy statements |
| private_subnets                    |              | list(string) | List of private subnet IDs                        |

## Resources Created
- aws_ecs_cluster.main
- aws_ecs_capacity_provider.ecs_ec2_capacity
- aws_ecs_cluster_capacity_providers.providers

- aws_iam_role.ecs_task_role
- aws_iam_policy.additional-task-policies
- aws_iam_role_policy_attachment.task_policy_attachments

- aws_iam_role.ecs_execution_role
- aws_iam_policy.additional-execution-policies
- aws_iam_role_policy_attachment.execution_policy_attachments
- aws_iam_role_policy_attachment.ecs-task-execution-role-policy-attachment

- aws_iam_role.ecs_agent
- aws_iam_role_policy_attachment.ecs_agent
- aws_iam_instance_profile.ecs_agent

- aws_launch_configuration.launch_conf
- aws_autoscaling_group.cluster_asg


## Output
| Output                  | Value                               | Type   | Description      |
|:----------------------- |:----------------------------------- |:------ |:---------------- |
| task_role_arn           | aws_iam_role.ecs_task_role.arn      | string | Self-explanatory |
| task_execution_role_arn | aws_iam_role.ecs_execution_role.arn | string | Self-explanatory |
| cluster_id              | aws_ecs_cluster.main.id             | string | Self-explanatory |
| cluster_name            | aws_ecs_cluster.main.name           | string | Self-explanatory |
