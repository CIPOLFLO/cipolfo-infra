variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "cipolflo"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "staging"
}
