output "db_instance_address" {
  value = aws_db_instance.mysql.address
}

output "db_password_ssm_arn" {
  value = aws_ssm_parameter.db_password.arn
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}