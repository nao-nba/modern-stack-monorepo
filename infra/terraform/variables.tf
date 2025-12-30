variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project_name" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database user"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true # パスワードなのでログに出さない設定
}

variable "db_root_password" {
  description = "Database root password"
  type        = string
  sensitive   = true
}