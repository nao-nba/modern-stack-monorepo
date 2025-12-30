output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  value       = aws_subnet.db[*].id
}

# 2. 【最重要】RDSモジュールで直接使う「サブネットグループ名」
output "db_subnet_group_name" {
  value       = aws_db_subnet_group.main.name
  description = "The name of the DB subnet group for RDS"
}