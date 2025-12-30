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

module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  
  # ALBモジュールからの出力を渡す
  alb_sg_id                 = module.alb.alb_sg_id
  alb_dns_name              = module.alb.alb_dns_name
  target_group_frontend_arn = module.alb.target_group_frontend_arn
  target_group_backend_arn  = module.alb.target_group_backend_arn

  # ECRモジュールからの出力を渡す
  frontend_ecr_url = module.ecr.frontend_repository_url
  backend_ecr_url  = module.ecr.backend_repository_url

  # DB設定（これらは terraform.tfvars から読み込む想定）
  db_host          = "db.local"
  db_name          = var.db_name
  db_user          = var.db_user
  db_password      = var.db_password
  db_root_password = var.db_root_password
}