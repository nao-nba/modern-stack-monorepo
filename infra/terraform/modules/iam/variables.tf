variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "db_password_ssm_arn" {
  type        = string
  description = "The ARN of the SSM parameter for DB password"
}