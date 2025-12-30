variable "project_name"       { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id"          { type = string }
variable "alb_dns_name"       { type = string }

# --- アプリが2つあるので、それぞれ2つ必要 ---
variable "target_group_frontend_arn" { type = string }
variable "target_group_backend_arn"  { type = string }

variable "frontend_ecr_url" { type = string }
variable "backend_ecr_url"  { type = string }

# --- DB接続用 ---
variable "db_host"     { type = string } # db.local を渡す
variable "db_name"     { type = string }
variable "db_user"     { type = string }
variable "db_password" { type = string }
variable "db_root_password" { type = string }