variable "ecs_task_execution_role_arn" {
  
}

variable "ecs_task_role_arn" {
  
}

variable "project_name" {
  
}

variable "container_image" {
  
}

variable "container_port" {
  
}

variable "cluster" {
  
}

variable "private_subnets" {
  type = set(string)
}

variable "public_subnets" {
  type = set(string)
}

variable "vpc_id" {
  
}

variable "container_definitions_json" {
  type = string
}