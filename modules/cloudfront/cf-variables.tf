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

variable "geo_restriction_type" {
  type = string
  default = "none"
  validation {
    condition = var.geo_restriction_type == "none" || var.geo_restriction_type == "whitelist" || var.geo_restriction_type == "blacklist"
    error_message = "Valid values are \"none\", \"whitelist\", \"blacklist\""
  }
}

variable "restriction_locations" {
  type = list(string)
  default = [ ]
}
