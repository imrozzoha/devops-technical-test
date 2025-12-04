# Application Load Balancer (ALB) Module

This module creates an internet-facing Application Load Balancer with health checks and target group configuration.

## Components

### Application Load Balancer
- **Type**: Application Load Balancer (Layer 7)
- **Scheme**: Internet-facing
- **Subnets**: Deployed across multiple public subnets for high availability
- **HTTP/2**: Enabled for improved performance

### Target Group
- **Port**: 8080 (application port)
- **Protocol**: HTTP
- **Health Check**:
  - Path: `/health`
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy threshold: 2 consecutive successful checks
  - Unhealthy threshold: 2 consecutive failed checks
  - Expected response: HTTP 200
- **Deregistration Delay**: 30 seconds (reduced from default 300s for faster deployments)

### Listener
- **Port**: 80 (HTTP)
- **Action**: Forward to target group
- Note: HTTPS listener not configured (no SSL certificate in dev environment)

## Design Decisions

### Internet-Facing ALB
The ALB is internet-facing to accept traffic from the public internet while EC2 instances remain in private subnets, providing a security layer.

### Health Check Configuration
The health check uses a dedicated `/health` endpoint to verify application availability. The 30-second interval balances between quick failure detection and avoiding unnecessary health check traffic.

### Multi-AZ Deployment
The ALB is deployed across multiple availability zones to ensure high availability and even traffic distribution.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name for resource naming | string | required |
| environment | Environment name | string | required |
| vpc_id | VPC ID where ALB will be created | string | required |
| public_subnet_ids | List of public subnet IDs for ALB | list(string) | required |
| alb_security_group_id | Security group ID for ALB | string | required |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ARN of the Application Load Balancer |
| alb_arn_suffix | ARN suffix of the ALB for CloudWatch metrics |
| alb_dns_name | DNS name to access the application |
| target_group_arn | ARN of the target group |
| target_group_arn_suffix | ARN suffix of the target group for CloudWatch |

## Cost Considerations

ALB pricing includes:
- Hourly charge: ~$0.0225/hour (~$16.20/month)
- LCU (Load Balancer Capacity Units) charges: Variable based on traffic
- For 1M requests/month evenly distributed: ~$6/month in LCU charges

## Tags

All resources are tagged with:
- Name: Descriptive resource name
- Environment: Environment identifier
- Project: Project name (via default_tags)
- ManagedBy: Terraform (via default_tags)
