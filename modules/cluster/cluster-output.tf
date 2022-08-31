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
  value = aws_lb_listener.http.arn
}

output "lb_dns_name" {
  value = aws_lb.main.dns_name
}