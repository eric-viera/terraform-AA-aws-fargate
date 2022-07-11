variable "vpc_cidr" {
  description = "CIDR block of the vpc"
}

variable "environment" {
  
}

variable "public_subnets_cidr" {
  type        = list
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list
  description = "CIDR block for Private Subnet"
}
