# Security Module

This module creates IAM roles and security groups following the principle of least privilege and defense-in-depth security strategy.

## Components

### IAM Role and Instance Profile
- **EC2 IAM Role**: Allows EC2 instances to assume role with minimal permissions
- **Attached Policies**:
  - `AmazonSSMManagedInstanceCore`: Enables AWS Systems Manager Session Manager for secure instance access without SSH
  - `CloudWatchAgentServerPolicy`: Allows CloudWatch agent to send logs and metrics

The IAM user deploying this infrastructure has restricted permissions following the least-privilege principle, only able to create and manage resources necessary for this application.

### Security Groups

#### ALB Security Group
- **Ingress**:
  - Port 80 (HTTP) from anywhere (0.0.0.0/0)
  - Port 443 (HTTPS) from anywhere (0.0.0.0/0)
- **Egress**: All traffic allowed (to communicate with EC2 instances)

#### EC2 Security Group
- **Ingress**:
  - Port 8080 only from ALB security group (layered security)
- **Egress**: All traffic allowed (for package updates via NAT Gateway)

## Security Best Practices Implemented

1. **No SSH Access**: Instances are accessed via AWS Systems Manager Session Manager instead of SSH keys
2. **Layered Security**: EC2 instances only accept traffic from the ALB on the application port
3. **Least Privilege IAM**: EC2 role has only the minimum required permissions
4. **Security Group References**: EC2 security group references ALB security group instead of CIDR blocks

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name for resource naming | string | required |
| environment | Environment name | string | required |
| vpc_id | VPC ID where security groups will be created | string | required |

## Outputs

| Name | Description |
|------|-------------|
| iam_role_arn | ARN of the IAM role for EC2 instances |
| iam_instance_profile_name | Name of the IAM instance profile |
| alb_security_group_id | ID of the ALB security group |
| ec2_security_group_id | ID of the EC2 security group |

## Tags

All resources are tagged with:
- Name: Descriptive resource name
- Environment: Environment identifier
- Project: Project name (via default_tags)
- ManagedBy: Terraform (via default_tags)
