# ECS autoscaling
Module to provision an autoscaling target group in AWS, for use with an ECS service.
The autoscaling target will allow the ecs service to provision new containers to meet demand an ensure the continued operation of the task.

## Input Variables
| Variable   | Defaut Value | Type |Description     |
|:-----------|:-------------|:-----|:---------------|
|cluster_name|              |string|Self-explanatory|
|service_name|              |string|Self-explanatory|

## Resources Created
- aws_appautoscaling_target.ecs_target
- aws_appautoscaling_policy.ecs_policy_memory
- aws_appautoscaling_policy.ecs_policy_cpu

## Output
None.
