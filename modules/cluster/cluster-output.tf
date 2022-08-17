output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "listener_arn" {
  value = aws_alb_listener.http.arn
}

output "domain_name" {
  value = data.aws_route53_zone.domain.name
}

output "zone_id" {
  value = data.aws_route53_zone.domain.id
}

output "lb_dns_name" {
  value = aws_lb.main.dns_name
}