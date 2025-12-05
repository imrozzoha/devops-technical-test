output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}/hello"
}

output "health_check_url" {
  description = "URL to check application health"
  value       = "http://${module.alb.alb_dns_name}/health"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = module.monitoring.log_group_name
}
