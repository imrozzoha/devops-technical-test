# Development Environment Configuration

aws_region   = "ap-southeast-2"
project_name = "devops-test"
environment  = "dev"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-southeast-2a", "ap-southeast-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# EC2 Configuration
instance_type = "t3.micro"

# Auto Scaling Configuration
asg_min_size           = 2
asg_max_size           = 4
asg_desired_capacity   = 2
target_cpu_utilization = 70

# Monitoring Configuration
log_retention_days = 7
