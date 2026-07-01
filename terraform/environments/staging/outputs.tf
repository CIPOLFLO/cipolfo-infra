output "alb_dns_name" {
  description = "URL del Load Balancer para acceder a la aplicacion"
  value       = module.alb.alb_dns_name
}

output "ecr_backend_url" {
  description = "URL del repositorio ECR del backend"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  description = "URL del repositorio ECR del frontend"
  value       = module.ecr.frontend_repository_url
}

output "rds_endpoint" {
  description = "Endpoint de la base de datos RDS"
  value       = module.rds.db_endpoint
}
