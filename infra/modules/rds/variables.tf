#########################################
# Project
#########################################

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

#########################################
# Database
#########################################

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

#########################################
# Network
#########################################

variable "private_db_subnets" {
  type = list(string)
}

variable "rds_security_group" {
  type = string
}

#########################################
# Database Configuration
#########################################

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "backup_retention_period" {
  type = number
}

variable "deletion_protection" {
  type = bool
}
