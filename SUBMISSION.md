# DevOps Technical Test - Submission

**Candidate:** Imrozzoha Chowdhury  
**Date:** 7-Dec-2025  
**Position:** Senior DevOps Engineer  
**Company:** EPAM / Cochlear  
**Repository:** https://github.com/imrozzoha/devops-technical-test

---

## Deliverables

### 1. Live Application URL

```
http://devops-test-dev-alb-2051043461.ap-southeast-2.elb.amazonaws.com/hello
```

**Status:** Deployed and tested  
**Response:** "OK" with HTTP 200

**Health Check Endpoint:**
```
http://devops-test-dev-alb-2051043461.ap-southeast-2.elb.amazonaws.com/health
```

### 2. GitHub Repository

https://github.com/imrozzoha/devops-technical-test

**Contains:**
- Complete Terraform infrastructure code (modular design)
- Node.js application with health checks
- Comprehensive documentation (6 documents)
- Architecture diagrams
- Alternative solutions analysis

### 3. Cost Estimate

**Monthly Cost:** ~$75 for 1M requests/month

**Breakdown:**
- EC2 (2x t3.micro): $16.94
- Application Load Balancer: $22.27
- NAT Gateway: $32.90
- EBS, CloudWatch, Data Transfer: $3.37

See [docs/COST_BREAKDOWN.md](docs/COST_BREAKDOWN.md) for detailed analysis.

### 4. Architecture Documentation

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for:
- High-level design overview
- Component descriptions
- Multi-AZ architecture
- Security design
- Mermaid diagrams

---

## Key Architectural Decisions

### Why EC2 + Auto Scaling instead of Lambda?

The test mentioned that Lambda, Elastic Beanstalk, and Kubernetes are "quick to set up but may not show off as much skill." I chose EC2 + Auto Scaling + ALB to demonstrate:

1. **Infrastructure Design Skills:**
   - Custom VPC architecture from scratch
   - Multi-AZ high availability design
   - Public/private subnet strategy
   - NAT Gateway and route table configuration

2. **Security Knowledge:**
   - Multi-layer security (VPC, Security Groups, IAM)
   - Least-privilege IAM roles
   - Network isolation patterns
   - No direct SSH access (SSM Session Manager)

3. **Production-Ready Patterns:**
   - Auto Scaling based on CPU metrics
   - Load balancing with health checks
   - CloudWatch monitoring and alarms
   - Proper logging and observability

### Cost vs High Availability Trade-offs

**Decision:** Single NAT Gateway in one AZ instead of Multi-AZ NAT Gateways

**Reasoning:**
- Saves $33/month (50% reduction in NAT costs)
- For a development/test environment, acceptable risk
- In production, would implement Multi-AZ NAT for full redundancy
- Shows cost-optimization thinking

**Other Optimizations:**
- t3.micro instances (right-sized for load)
- 7-day log retention (vs 30+ days)
- HTTP only (no ACM certificate costs)

---

## Testing Results

**Tested:** 2025-12-07 16:08

All endpoints verified working:
- GET /hello - Returns "OK" with HTTP 200
- GET /health - Returns "healthy" with HTTP 200

Infrastructure verified:
- Auto Scaling Group: 2 instances running in ap-southeast-2a and ap-southeast-2b
- Scaling policy: Configured to scale up to 4 instances on high CPU
- Load Balancer: Traffic distributing correctly across both instances
- Health checks: ALB health checks passing (30 second intervals)
- CloudWatch: Logs and metrics flowing to /aws/ec2/devops-test-dev
- Alarms: CPU threshold and unhealthy target alarms configured

---

## Documentation Index

1. **[ARCHITECTURE.md](docs/ARCHITECTURE.md)**  
   Design decisions, component descriptions, diagrams

2. **[COST_BREAKDOWN.md](docs/COST_BREAKDOWN.md)**  
   Detailed monthly cost analysis with optimization options

3. **[DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)**  
   Step-by-step deployment and testing procedures

4. **[ALTERNATIVE_SOLUTIONS.md](docs/ALTERNATIVE_SOLUTIONS.md)**  
   Comparison of 7 different architectures:
   - EC2 + ASG + ALB (chosen)
   - Lambda + API Gateway
   - ECS Fargate + ALB
   - ECS on EC2 + ALB
   - Elastic Beanstalk
   - EKS
   - CloudFront + API Gateway

5. **[SECURITY.md](docs/SECURITY.md)**  
   Security implementation and best practices

6. **[ASSUMPTIONS.md](docs/ASSUMPTIONS.md)**  
   Project scope and constraints

---

## Skills Demonstrated

### Infrastructure
- VPC design and networking  
- Multi-AZ high availability  
- Auto Scaling configurations  
- Load balancing strategies  
- Security group architecture  

### Security
- IAM roles and policies (least-privilege)  
- Network isolation  
- Multi-layer security  
- Encryption at rest and in transit  

### DevOps Practices
- Infrastructure as Code (Terraform)  
- Modular code design  
- State management (S3 + DynamoDB)  
- Monitoring and observability  
- Documentation quality  

### Cloud Architecture
- Cost optimization  
- Trade-off analysis  
- Alternative solutions evaluation  
- Production-ready patterns  

---

## Future Enhancements

If deploying to production, I would add:

1. **Security:**
   - HTTPS with ACM certificate
   - WAF for DDoS protection
   - AWS Shield Advanced
   - GuardDuty for threat detection

2. **High Availability:**
   - Multi-AZ NAT Gateways
   - Cross-region replication
   - Route53 health checks

3. **Monitoring:**
   - Enhanced CloudWatch metrics
   - AWS X-Ray for tracing
   - Extended log retention
   - SNS notifications for all alarms

4. **CI/CD:**
   - GitHub Actions pipeline
   - Automated testing
   - Blue-green deployments
   - Automated rollbacks

5. **Cost Optimization:**
   - Reserved Instances (40% savings)
   - VPC Endpoints (reduce NAT costs)
   - Auto Scaling schedule (scale down overnight)

---

## Thank You

Thank you for reviewing my submission. I am happy to discuss any architectural decisions and answer questions about the implementation, or provide additional clarification.

The repository demonstrates not just the ability to deploy infrastructure, but understanding of:
- When to choose different solutions
- How to balance cost vs features
- Security best practices
- Production-ready patterns

I look forward to discussing this further.

**Imrozzoha Chowdhury**  
7-Dec-2025