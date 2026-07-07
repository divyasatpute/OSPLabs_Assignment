variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group" {
  description = "ALB Security Group ID"
  type        = string
}

variable "target_port" {
  description = "Application Port"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB Health Check Path"
  type        = string
  default     = "/"
}
