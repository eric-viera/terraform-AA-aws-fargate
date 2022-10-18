variable "domain" {
  type        = string
  description = "Hosted zone domain name"
}

variable "environment" {
  type        = string
  description = "name of this environment"
}

variable "project" {
  type        = string
  description = "name of the project"
}

variable "lambda_arn" {
  type    = string
  default = ""
}

variable "event" {
  type    = string
  default = ""
}

variable "name_prefix" {
  type = string
  default = ""
}
