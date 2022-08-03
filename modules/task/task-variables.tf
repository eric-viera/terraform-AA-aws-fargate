variable "ecs_task_execution_role_arn" {
  
}

variable "ecs_task_role_arn" {
  
}

variable "project_name" {
  description = "what will you call this project?"
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

variable "private_subnets" {
  type = set(string)
  description = "A set of private subnet IDs"
}

variable "public_subnets" {
  type = set(string)
  description = "A set of public subnet IDs"
}

variable "vpc_id" {
  description = "id of the vpc"
}

variable "container_definitions_json" {
  type = string
  description = "a json-encoded string with the container definition"
}

variable "launch_type" {
  type = string
  description = "The valid values are EC2 and FARGATE."
}

variable "cpu" {
  description = "Number of cpu units used by the task. 1 VCPU = 1024 cpu units"
  type = number
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task. "
  type = number
}

variable "listener_port" {
  description = "Port on which the load balancer is listening"
  type = number
}

variable "listener_protocol" {
  description = "Protocol for connections from clients to the load balancer, valid values are HTTP and HTTPS"
  type = string
}

variable "target_group_protocol" {
  description = "Protocol to use for routing traffic to the targets. Should be one of GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS, or UDP"
  type = string
}

variable "strategy" {
  type = string
  description = "Scheduling strategy to use for the service. Valid values are REPLICA and DAEMON."
  default = "REPLICA"
}