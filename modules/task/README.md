# ECS Service
Module to provision a load balanced ECS service, and a task to be used in an ECS cluster in AWS.
A task is a docker container that will run until its funtion exits or returns an error.
A service is an artifact that makes sure that there are always at least two containers running, to ensure the continued availability of your task.

## Input Variables
| Variable                    | Type        | Description                                                                                              |
|:--------------------------- |:----------- |:-------------------------------------------------------------------------------------------------------- |
| ecs_task_execution_role_arn | string      | Self-explanatory                                                                                         |
| ecs_task_role_arn           | string      | Self-explanatory                                                                                         |
| project_name                | string      | What will you call this project?                                                                         |
| container_image             | string      | The name and tag of the docker image                                                                     |
| container_port              | number      | Port exposed by the docker image                                                                         |
| cluster                     | string      | The cluster id                                                                                           |
| private_subnets             | set(string) | A set of private subnet IDs                                                                              |
| public_subnets              | set(string) | A set of public subnet IDs                                                                               |
| vpc_id                      | string      | ID of the VPC                                                                                            |
| container_definitions_json  | string      | A json-encoded string with the container definition                                                      |
| launch_type                 | string      | The valid values are "EC2" and "FARGATE"                                                                 |
| cpu                         | number      | Number of cpu units used by the task. 1 vCPU = 1024 cpu units                                            |
| memory                      | number      | Amount (in MiB) of memory used by the task                                                               |
| listener_port               | number      | Port on which the load balancer is listening                                                             |
| listener_protocol           | string      | Protocol for connections from clients to the load balancer, valid values are HTTP and HTTPS              |
| strategy                    | string      | Scheduling strategy to use for the service. Valid values are REPLICA and DAEMON. Defaults to REPLICA     |
| target_group_protocol       | string      | Protocol for routing traffic to targets. Should be one of GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS, or UDP |

## Resources Created
- aws_ecs_task_definition.main
- aws_ecs_service.main
- aws_lb.main
- aws_alb_target_group.main
- aws_alb_listener.http
- aws_security_group.alb
- aws_security_group.ecs_tasks

## Output
| Output       | Value                     | Type   | Description      |
|:------------ |:------------------------- |:------ |:---------------- |
| service_name | aws_ecs_service.main.name | string | Self-explanatory |
