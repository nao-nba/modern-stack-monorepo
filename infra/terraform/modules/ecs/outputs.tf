output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name_frontend" {
  value = aws_ecs_service.frontend.name
}

output "ecs_app_sg_id" {
  value       = aws_security_group.ecs_app.id
  description = "The ID of the security group for ECS applications (Front/Back)"
}