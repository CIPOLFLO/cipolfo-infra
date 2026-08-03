variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cipolflo"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "auth0_issuer_uri" {
  type = string
}

variable "auth0_audience" {
  type = string
}

variable "auth0_domain" {
  type = string
}

variable "auth0_client_id" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "cipolflo.com.uy"
}

# Vacio = dominio raiz (cipolflo.com.uy). Si se usa subdominio, poner "www" o el que corresponda.
variable "subdomain" {
  type    = string
  default = ""
}

variable "azure_document_intelligence_endpoint" {
  type = string
}

variable "azure_document_intelligence_key" {
  type      = string
  sensitive = true
}

variable "mail_username" {
  type = string
}

variable "mail_password" {
  type      = string
  sensitive = true
}

variable "reporte_reservas_destinatario" {
  type    = string
  default = ""
}

variable "telegram_bot_token" {
  type      = string
  sensitive = true
}

variable "telegram_webhook_secret" {
  type      = string
  sensitive = true
}

variable "ai_api_key" {
  type      = string
  sensitive = true
}
