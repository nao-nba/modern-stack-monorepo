module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
}


module "rds" {
  source        = "./modules/rds"
  project_name      = var.project_name
  vpc_id        = module.network.vpc_id
  az_names = module.network.az_names
}

module "iam" {
  source              = "./modules/iam"
  project_name        = var.project_name
  db_password_ssm_arn = module.rds.db_password_ssm_arn # RDSからパスワードの場所を教えてもらう
}


module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn

  # ALBモジュールからの出力を渡す
  alb_sg_id                 = module.alb.alb_sg_id
  alb_dns_name              = module.alb.alb_dns_name
  target_group_frontend_arn = module.alb.target_group_frontend_arn
  target_group_backend_arn  = module.alb.target_group_backend_arn

  # ECRモジュールからの出力を渡す
  frontend_ecr_url = module.ecr.frontend_repository_url
  backend_ecr_url  = module.ecr.backend_repository_url

  # RDSモジュールからの出力を渡す
  execution_role_arn = module.iam.ecs_task_execution_role_arn # IAMからロールを借りる
  db_host            = module.rds.db_instance_address
  db_password_arn    = module.rds.db_password_ssm_arn

  # RDSができてからECSを動かすことを明示
  depends_on = [module.rds]
}


resource "aws_security_group_rule" "db_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.ecs.ecs_app_sg_id # ECSから貰う
  security_group_id        = module.rds.db_sg_id     # RDSから貰う
}