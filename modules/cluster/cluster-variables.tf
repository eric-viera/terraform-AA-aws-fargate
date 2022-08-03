variable "project_name" {
  type = string
}

variable "additional_role_policies" {
  type = list(string)
  description = "list of json strings containing policy statements"
}

variable "additional_execution_role_policies" {
  type = list(string)
  description = "list of json strings containing policy statements"
}

variable "private_subnets" {
  type = list(string)
  description = "list of private subnet IDs"
}