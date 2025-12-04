# VPC Module

This module creates a highly available VPC infrastructure with public and private subnets across multiple availability zones.

## Architecture

- VPC with customizable CIDR block (default: 10.0.0.0/16)
- 2 public subnets (10.0.1.0/24, 10.0.2.0/24) across 2 AZs
- 2 private subnets (10.0.11.0/24, 10.0.12.0/24) across 2 AZs
- Internet Gateway for public subnet internet access
- Single NAT Gateway in the first public subnet (cost optimization)
- Proper routing tables for public and private subnets

## Design Decisions

### Single NAT Gateway
For cost optimization in a development environment, this module uses a single NAT Gateway instead of one per AZ. This saves approximately $32/month per NAT Gateway but reduces high availability. In production, consider deploying a NAT Gateway in each AZ.

### Multi-AZ Public Subnets
Public subnets are distributed across two availability zones to ensure the Application Load Balancer can distribute traffic evenly and maintain availability if one AZ experiences issues.

### Private Subnets for Application Tier
EC2 instances run in private subnets with no direct internet access, following security best practices. They access the internet through the NAT Gateway for package updates and external API calls.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name for resource naming | string | required |
| environment | Environment name | string | required |
| vpc_cidr | CIDR block for VPC | string | required |
| azs | List of availability zones | list(string) | required |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | required |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | required |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | IDs of public subnets |
| private_subnet_ids | IDs of private subnets |
| nat_gateway_id | ID of the NAT Gateway |

## Tags

All resources are tagged with:
- Name: Descriptive resource name
- Environment: Environment identifier
- Project: Project name (via default_tags)
- ManagedBy: Terraform (via default_tags)
