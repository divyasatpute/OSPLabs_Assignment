variable "project_name" {}

variable "environment" {}

variable "region" {}

variable "vpc_cidr" {}

variable "public_subnets" {
  type = list(string)
}

variable "private_app_subnets" {
  type = list(string)
}

variable "private_db_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}
