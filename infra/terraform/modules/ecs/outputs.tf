# modules/ecs/outputs.tf の例
output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name_frontend" {
  value = aws_ecs_service.frontend.name
}