variable "ecs_task_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "project_name" {
  description = "what will you call this project?"
}

variable "service_name" {
  type        = string
  description = "the name for this particular service"
}

variable "domain" {
  type        = string
  description = "the name of the hosted zone"
}

variable "container_image" {
  description = "The name and tag of the docker image i.e. \"pengbai/docker-supermario:latest\""
}

variable "container_port" {
  description = "port exposed by the docker image"
}

variable "cluster" {
  description = "the cluster id"
}

variable "cluster_name" {
  description = "the cluster name"
}

variable "private_subnets" {
  type        = set(string)
  description = "A set of private subnet IDs"
}

variable "public_subnets" {
  type        = set(string)
  description = "A set of public subnet IDs"
}

variable "vpc_id" {
  description = "id of the vpc"
}

variable "launch_type" {
  type        = string
  description = "The valid values are EC2 and FARGATE."
}

variable "cpu" {
  description = "Number of cpu units used by the task. 1 VCPU = 1024 cpu units"
  type        = number
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task. "
  type        = number
}

variable "listener_arn" {
  type = string
}

variable "target_group_protocol" {
  description = "Protocol to use for routing traffic to the targets. Should be one of GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS, or UDP"
  type        = string
}

variable "strategy" {
  type        = string
  description = "Scheduling strategy to use for the service. Valid values are REPLICA and DAEMON."
  default     = "REPLICA"
}

variable "lb_dns_name" {
  type        = string
  description = "dns name for the load balancer"
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_code" {
  type    = string
  default = "200"
}

variable "health_check_port" {
  type    = string
  default = "traffic-port"
}


variable "added_sgs" {
  type        = list(string)
  description = "list of security groups to assign tasks to"
  default     = []
}

variable "alarm_action_arns" {
  type        = list(string)
  default     = []
  description = "List of actions to execute when the alarm transitions into ALARM state from any other state. Each action is specified as an ARN"
}

variable "ok_action_arns" {
  type        = list(string)
  default     = []
  description = "List of actions to execute when the alarm transitions into OK state from any other state. Each action is specified as an ARN"
}
