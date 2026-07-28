terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

module "networking" {
  source       = "../../modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

module "rds" {
  source                = "../../modules/rds"
  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  deletion_protection   = true
  skip_final_snapshot   = false
}

module "alb" {
  source                = "../../modules/alb"
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
}

module "ecs" {
  source                    = "../../modules/ecs"
  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  private_subnet_ids        = module.networking.private_subnet_ids
  public_subnet_ids         = module.networking.public_subnet_ids
  ecs_security_group_id     = module.networking.ecs_security_group_id
  backend_target_group_arn  = module.alb.backend_target_group_arn
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  backend_image             = "${module.ecr.backend_repository_url}:latest"
  frontend_image            = "${module.ecr.frontend_repository_url}:latest"
  db_endpoint               = module.rds.db_endpoint
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  auth0_issuer_uri          = var.auth0_issuer_uri
  auth0_audience            = var.auth0_audience
  auth0_domain              = var.auth0_domain
  auth0_client_id           = var.auth0_client_id
  backend_url               = "http://${module.alb.alb_dns_name}"

  azure_document_intelligence_endpoint = var.azure_document_intelligence_endpoint
  azure_document_intelligence_key      = var.azure_document_intelligence_key
  mail_username                        = var.mail_username
  mail_password                        = var.mail_password
  reporte_reservas_destinatario        = var.reporte_reservas_destinatario
  telegram_bot_token                   = var.telegram_bot_token
  telegram_webhook_secret              = var.telegram_webhook_secret
  ai_api_key                           = var.ai_api_key
}
