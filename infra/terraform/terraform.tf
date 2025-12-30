terraform {
  required_version = "~> 1.0"
  backend "s3" {
    bucket = "nao-nba-s3"
    key    = "todo-app/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}