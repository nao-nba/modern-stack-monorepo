variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "alb_dns_name" { type = string }

# --- アプリが2つあるので、それぞれ2つ必要 ---
variable "target_group_frontend_arn" { type = string }
variable "target_group_backend_arn" { type = string }

variable "frontend_ecr_url" { type = string }
variable "backend_ecr_url" { type = string }

variable "execution_role_arn" { type = string }
variable "db_password_arn" { type = string }

variable "db_host" { type = string }

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "IAM execution role ARN for ECS tasks"
}