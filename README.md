# DevOps Technical Test

> **📋 Complete submission details: [SUBMISSION.md](SUBMISSION.md)**

My solution for the DevOps Engineer technical assessment at EPAM/Cochlear.

## What I Built

Production-grade AWS infrastructure using EC2 + Auto Scaling + Application Load Balancer. I chose this approach over Lambda/Elastic Beanstalk to demonstrate deeper infrastructure knowledge.

## Why This Architecture

The test mentioned that Lambda and Elastic Beanstalk are "quick to set up" but may not show as much skill. I wanted to demonstrate:

- **VPC Design:** Custom VPC with public/private subnet architecture from scratch
- **Security:** Multi-layer security with Security Groups and IAM roles
- **High Availability:** Multi-AZ deployment with Auto Scaling
- **Monitoring:** CloudWatch logs, metrics, and alarms
- **Cost Optimization:** Single NAT Gateway to balance cost vs HA

## Architecture Overview

- Custom VPC (10.0.0.0/16) across 2 Availability Zones
- Public subnets for Application Load Balancer
- Private subnets for EC2 instances
- Auto Scaling Group (2-4 t3.micro instances)
- CloudWatch monitoring and alarms

## Cost Analysis

Monthly cost: ~$75 for 1M requests/month

Main cost drivers:
- NAT Gateway: $33/month (biggest expense, chose single-AZ to save costs)
- Application Load Balancer: $22/month
- EC2 instances: $17/month (2x t3.micro 24/7)

See [docs/COST_BREAKDOWN.md](docs/COST_BREAKDOWN.md) for detailed breakdown and optimization options.

## Quick Start
```powershell
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="environments/dev/terraform.tfvars"

# Deploy infrastructure
terraform apply -var-file="environments/dev/terraform.tfvars"

# Test the application
$ALB_DNS = terraform output -raw alb_dns_name
Invoke-WebRequest "http://$ALB_DNS/hello"
```

## Application Endpoints

Once deployed:
- `http://YOUR-ALB-DNS/hello` → Returns "OK" with HTTP 200
- `http://YOUR-ALB-DNS/health` → Returns "healthy" with HTTP 200

## Documentation

- **[Architecture Design](docs/ARCHITECTURE.md)** - Design decisions and justifications
- **[Cost Breakdown](docs/COST_BREAKDOWN.md)** - Detailed monthly cost analysis
- **[Alternative Solutions](docs/ALTERNATIVE_SOLUTIONS.md)** - Comparison of 7 different approaches
- **[Security](docs/SECURITY.md)** - Security implementation details
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[Assumptions](docs/ASSUMPTIONS.md)** - Project assumptions and constraints

## Key Decisions

**EC2 vs Lambda:** EC2 approach demonstrates infrastructure depth vs serverless simplicity

**Single NAT Gateway:** Cost optimization (saves $33/month) vs full multi-AZ redundancy

**t3.micro instances:** Right-sized for the load, cost-effective

**No SSL:** HTTP only to keep it simple (SSL would add ACM + Route53 costs)

---

Built by Imrozzoha Chowdhury for EPAM/Cochlear DevOps Engineer Technical Assessment