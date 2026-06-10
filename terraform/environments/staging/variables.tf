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
  default = "staging"
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

variable "subdomain" {
  type    = string
  default = "staging"
}
