#############################################
# ALB Outputs
#############################################

output "alb_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted Zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

#############################################
# Target Group Outputs
#############################################

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Target Group Name"
  value       = aws_lb_target_group.this.name
}

output "listener_arn" {
  description = "HTTP Listener ARN"
  value       = aws_lb_listener.http.arn
}
