output "service_name" {
  value = aws_ecs_service.main.name
}

output "fqdn" {
  value = aws_route53_record.record.fqdn
}
