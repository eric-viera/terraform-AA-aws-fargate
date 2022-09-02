variable "project_name" {
  type = string
}

variable "additional_role_policies" {
  type        = list(string)
  description = "list of json strings containing policy statements"
}

variable "additional_execution_role_policies" {
  type        = list(string)
  description = "list of json strings containing policy statements"
}

variable "private_subnets" {
  type        = list(string)
  description = "list of private subnet IDs"
}

variable "public_subnets" {
  type        = list(string)
  description = "list of public subnet IDs"
}

variable "domain" {
  type        = string
  description = "name of the hosted zone"
  default     = "acklenavenueclient.com"
}

variable "listener_port" {
  description = "Port on which the load balancer is listening"
  type        = number
}

variable "listener_protocol" {
  description = "Protocol for connections from clients to the load balancer, valid values are HTTP and HTTPS"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "id of the vpc"
}

variable "added_sgs" {
  type        = list(string)
  description = "list of security groups to assign tasks to"
  default     = []
}
