output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer. Open this in a browser to reach the app."
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (only reachable from inside the VPC, i.e. from ECS tasks)."
  value       = module.rds.db_endpoint
}

output "rds_port" {
  value = module.rds.db_port
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
