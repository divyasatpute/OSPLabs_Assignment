#########################################
# Project Information
#########################################

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment Name"
  type        = string
}

#########################################
# Network
#########################################

variable "private_subnets" {
  description = "Private App Subnet IDs"
  type        = list(string)
}

variable "ecs_security_group" {
  description = "ECS Security Group"
  type        = string
}

#########################################
# Load Balancer
#########################################

variable "target_group_arn" {
  description = "Target Group ARN"
  type        = string
}

#########################################
# IAM
#########################################

variable "execution_role_arn" {
  description = "IAM Execution Role ARN"
  type        = string
}

#########################################
# CloudWatch Logs
#########################################

variable "log_group_name" {
  description = "CloudWatch Log Group Name"
  type        = string
}

#########################################
# Container
#########################################

variable "container_name" {
  description = "Container Name"
  type        = string

  default = "nginx"
}

variable "container_image" {
  description = "Docker Image"

  type = string

  default = "nginx:latest"
}

variable "container_port" {

  description = "Application Port"

  type = number

  default = 80

}

#########################################
# ECS Resources
#########################################

variable "cpu" {

  description = "Task CPU"

  type = number

  default = 256

}

variable "memory" {

  description = "Task Memory"

  type = number

  default = 512

}

variable "desired_count" {

  description = "Desired ECS Tasks"

  type = number

  default = 2

}
#########################################
# AWS Region
#########################################

variable "region" {
  description = "AWS Region"
  type        = string
}
