##############################################
# ECS Cluster Outputs
##############################################

output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.this.name
}

##############################################
# ECS Service Outputs
##############################################

output "service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.this.name
}

##############################################
# Task Definition Outputs
##############################################

output "task_definition_arn" {
  description = "Task Definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task Definition Family"
  value       = aws_ecs_task_definition.this.family
}
