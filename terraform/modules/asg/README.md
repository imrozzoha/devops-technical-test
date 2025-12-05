# Auto Scaling Group (ASG) Module

This module creates an Auto Scaling Group with EC2 instances running the application in private subnets.

## Components

### Launch Template
- **AMI**: Latest Amazon Linux 2023 (automatically selected)
- **Instance Type**: t3.micro (configurable)
- **User Data**: Bootstrap script from `scripts/user-data.sh`
- **IAM Instance Profile**: Attached for SSM and CloudWatch access
- **Security Group**: EC2 security group (port 8080 from ALB only)
- **IMDSv2**: Required (enhanced instance metadata security)
- **Monitoring**: Detailed monitoring enabled

### Auto Scaling Group
- **Capacity**:
  - Minimum: 2 instances
  - Maximum: 4 instances
  - Desired: 2 instances
- **Subnets**: Private subnets across multiple AZs
- **Health Check**: ELB-based with 300s grace period
- **Target Group**: Attached to ALB target group
- **Metrics**: Full set of CloudWatch metrics enabled

### Auto Scaling Policy
- **Type**: Target Tracking Scaling
- **Metric**: Average CPU Utilization
- **Target**: 70%
- **Behavior**: Automatically scales out when CPU > 70%, scales in when CPU < 70%

## Design Decisions

### Multi-AZ Deployment
Instances are distributed across multiple availability zones for high availability. If one AZ fails, instances in other AZs continue serving traffic.

### Private Subnets
EC2 instances run in private subnets with no direct internet access, enhancing security. They access the internet through the NAT Gateway for updates.

### ELB Health Checks
Using ELB health checks instead of EC2 health checks ensures instances are terminated if they fail application-level health checks, not just instance-level checks.

### Target Tracking Policy
The target tracking policy automatically calculates the correct number of instances needed to maintain 70% average CPU utilization, simplifying operations compared to step scaling policies.

### IMDSv2 Required
Instance Metadata Service version 2 (IMDSv2) is required, which uses session-oriented requests to prevent certain types of SSRF attacks.

## User Data Script

The launch template references `scripts/user-data.sh` which:
1. Updates the system
2. Installs Node.js 18.x
3. Deploys the application code
4. Creates a systemd service
5. Configures CloudWatch agent

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name for resource naming | string | required |
| environment | Environment name | string | required |
| vpc_id | VPC ID | string | required |
| private_subnet_ids | List of private subnet IDs | list(string) | required |
| ec2_security_group_id | Security group ID for EC2 | string | required |
| iam_instance_profile | IAM instance profile name | string | required |
| target_group_arn | ARN of the ALB target group | string | required |
| instance_type | EC2 instance type | string | t3.micro |
| min_size | Minimum instances | number | 2 |
| max_size | Maximum instances | number | 4 |
| desired_capacity | Desired instances | number | 2 |
| target_cpu_utilization | Target CPU % for scaling | number | 70 |
| log_group_name | CloudWatch log group name | string | required |

## Outputs

| Name | Description |
|------|-------------|
| asg_name | Name of the Auto Scaling Group |
| asg_arn | ARN of the Auto Scaling Group |
| launch_template_id | ID of the launch template |

## Cost Considerations

For t3.micro instances in ap-southeast-2:
- On-Demand: $0.0136/hour per instance
- 2 instances 24/7: ~$16.94/month
- Reserved Instances (1-year): ~40% savings

## Tags

All resources are tagged with:
- Name: Descriptive resource name
- Environment: Environment identifier
- Project: Project name (via default_tags)
- ManagedBy: Terraform (via default_tags)
