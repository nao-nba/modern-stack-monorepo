output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Frontendの環境変数に使用するALBのDNS名"
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "target_group_frontend_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "target_group_backend_arn" {
  value = aws_lb_target_group.backend.arn
}