data "aws_route53_zone" "hosted_zone" {
  name = var.domain
}

data "aws_region" "current" {
  
}