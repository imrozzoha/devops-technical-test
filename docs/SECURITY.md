# Security Documentation

This document outlines the security measures implemented in this AWS infrastructure, following AWS security best practices and the principle of least privilege.

## Security Overview

This infrastructure implements defense-in-depth security with multiple layers:
1. **Network Isolation**: VPC with public/private subnet separation
2. **Security Groups**: Layered firewall rules
3. **IAM Least Privilege**: Minimal required permissions for resources and users
4. **Encryption**: Data encryption at rest and in transit
5. **Monitoring**: CloudWatch logging for audit trails
6. **No SSH**: Secure access via AWS Systems Manager

---

## Network Security

### VPC Design

**Network Isolation**:
- **VPC CIDR**: 10.0.0.0/16 (private IP space)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (only for ALB and NAT Gateway)
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24 (for EC2 instances)

**Design Principles**:
1. **Separation of Concerns**: Public-facing resources (ALB) in public subnets, application instances in private subnets
2. **No Direct Internet Access**: EC2 instances cannot be directly accessed from the internet
3. **Controlled Egress**: Internet access only through NAT Gateway for updates and API calls

### Routing Tables

**Public Route Table**:
```
Destination     Target
10.0.0.0/16     local
0.0.0.0/0       Internet Gateway
```
- Allows internet-bound traffic directly through IGW

**Private Route Table**:
```
Destination     Target
10.0.0.0/16     local
0.0.0.0/0       NAT Gateway
```
- Routes internet traffic through NAT Gateway
- Instances have no public IP addresses

### Internet Gateway vs NAT Gateway

**Internet Gateway**: Used for public subnets
- Allows bidirectional traffic
- Resources must have public IPs
- ALB uses this for public internet access

**NAT Gateway**: Used for private subnets
- Allows outbound traffic only
- Translates private IPs to public IP
- EC2 instances use this for package updates

---

## Security Groups

Security groups act as virtual firewalls controlling inbound and outbound traffic.

### ALB Security Group

**Inbound Rules**:
| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 80 | TCP | 0.0.0.0/0 | HTTP from internet |
| 443 | TCP | 0.0.0.0/0 | HTTPS from internet (future) |

**Outbound Rules**:
| Port | Protocol | Destination | Purpose |
|------|----------|-------------|---------|
| All | All | 0.0.0.0/0 | Allow all outbound |

**Security Notes**:
- Accepts traffic from anywhere (public-facing application)
- Future enhancement: Could restrict to specific countries/regions with WAF
- Outbound allows health checks to EC2 instances

### EC2 Security Group

**Inbound Rules**:
| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 8080 | TCP | ALB Security Group | Application traffic from ALB only |

**Outbound Rules**:
| Port | Protocol | Destination | Purpose |
|------|----------|-------------|---------|
| All | All | 0.0.0.0/0 | Package updates, AWS APIs |

**Security Notes**:
- **No direct internet access**: Only accepts traffic from ALB
- **Security group chaining**: References ALB security group instead of CIDR blocks
- **No SSH port open**: Port 22 is not open (uses SSM instead)
- Outbound allows NAT Gateway access for updates

### Layered Security Approach

```
Internet
   ↓
[ALB Security Group] ← Allows HTTP/HTTPS from 0.0.0.0/0
   ↓
[EC2 Security Group] ← Allows port 8080 from ALB SG only
   ↓
Application
```

This creates two layers of firewall protection. Even if ALB is compromised, attackers cannot directly access EC2 instances on other ports.

---

## IAM Security

### Principle of Least Privilege

All IAM roles and policies follow the principle of least privilege, granting only the minimum permissions required.

### IAM User (Deployment)

The IAM user deploying this infrastructure has restricted permissions following the least-privilege principle:

**Required Permissions** (minimal set):
- **EC2**: Launch instances, manage VPC resources, security groups
- **IAM**: Create/manage roles and policies for EC2 instances
- **ELB**: Create and manage load balancers and target groups
- **Auto Scaling**: Manage ASG and launch templates
- **CloudWatch**: Create log groups, metrics, and alarms
- **S3**: Read/write access to Terraform state bucket only
- **DynamoDB**: Read/write access to state lock table only

**Not Included** (demonstrating restrictions):
- No ability to create/modify other IAM users
- No access to billing or cost management
- No ability to modify account-level settings
- No access to other AWS services not required
- No ability to elevate privileges

### EC2 IAM Role

**Role Name**: `devops-test-dev-ec2-role`

**Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Attached Policies**:

1. **AmazonSSMManagedInstanceCore** (AWS Managed Policy)
   - Enables AWS Systems Manager Session Manager
   - Allows instance to register with SSM
   - Provides secure shell access without SSH
   - CloudWatch and S3 access for SSM functionality

2. **CloudWatchAgentServerPolicy** (AWS Managed Policy)
   - Allows CloudWatch agent to publish metrics
   - Enables log uploads to CloudWatch Logs
   - Provides read access to CloudWatch configurations

**What EC2 Cannot Do**:
- Cannot create or modify IAM roles/policies
- Cannot launch other EC2 instances
- Cannot modify security groups or network ACLs
- Cannot access S3 buckets except for SSM/CloudWatch
- Cannot modify or delete CloudWatch logs
- Cannot access other AWS accounts

### Instance Profile

The instance profile links the IAM role to EC2 instances:
```hcl
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devops-test-dev-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

---

## Access Control

### No SSH Access

**Traditional Approach** (Not Used):
- SSH keys stored on developer machines
- Port 22 open in security groups
- Risk of key compromise
- Difficult key rotation
- No centralized access logging

**Our Approach** (Session Manager):
- **No SSH port open**: Port 22 is not in security groups
- **No SSH keys**: No keys to manage or rotate
- **IAM-based access**: Access controlled via IAM policies
- **Audit logging**: All sessions logged in CloudWatch
- **No public IPs needed**: Works through SSM service endpoints

**Connecting to Instances**:
```powershell
# No SSH key needed
aws ssm start-session --target i-1234567890abcdef0
```

**Benefits**:
1. **Centralized Access Management**: All access through IAM
2. **Audit Trail**: Every session logged with user identity
3. **No Exposed Ports**: Attack surface reduced
4. **MFA Support**: Can require MFA for SSM access
5. **Temporary Credentials**: No long-lived SSH keys

### Session Manager Configuration

- **Enabled via**: AmazonSSMManagedInstanceCore policy
- **No additional cost**: Included with EC2
- **Logging**: All sessions logged to CloudWatch
- **Encryption**: Sessions encrypted using TLS
- **Port Forwarding**: Supports port forwarding securely

---

## Data Encryption

### Encryption at Rest

**EBS Volumes**:
- EC2 instances use EBS root volumes
- **Recommendation**: Enable default EBS encryption at account level
- **Encryption**: AES-256 encryption
- **Key Management**: AWS-managed keys (default) or customer-managed KMS keys
- **Performance**: No noticeable performance impact

**Enable Default Encryption**:
```powershell
aws ec2 enable-ebs-encryption-by-default --region ap-southeast-2
```

**CloudWatch Logs**:
- Log groups encrypted at rest by default
- Can use KMS keys for additional control
- Logs in `/aws/ec2/devops-test-dev` are encrypted

**S3 (Terraform State)**:
- Terraform state bucket should have encryption enabled
- AES-256 or KMS encryption
- Versioning enabled for backup and recovery

### Encryption in Transit

**ALB to EC2**:
- Currently HTTP (port 8080)
- Within VPC (isolated network)
- **Production recommendation**: Use HTTPS between ALB and targets

**Internet to ALB**:
- Currently HTTP only (port 80)
- **Production requirement**: HTTPS with ACM certificate
- TLS 1.2+ for security

**AWS API Calls**:
- All AWS API calls use HTTPS
- SDK and CLI enforce TLS by default

**CloudWatch and SSM**:
- All data transmitted over HTTPS
- TLS 1.2+ encryption

---

## Monitoring and Logging

### CloudWatch Logs

**Application Logs**:
- **Log Group**: `/aws/ec2/devops-test-dev`
- **Retention**: 7 days (configurable)
- **Purpose**: Application output, errors, and debugging
- **Access**: Restricted via IAM policies

**Log Security**:
- Encrypted at rest
- Access logged in CloudTrail
- Retention policy prevents indefinite storage
- Cannot be modified after ingestion

### CloudWatch Metrics

**Monitored Metrics**:
- EC2 CPU, network, disk utilization
- ALB request count, response time, error rates
- ASG scaling activities
- Custom metrics via CloudWatch agent

**Alarms**:
1. **High CPU**: Triggers at >80% for 2 periods
2. **Unhealthy Targets**: Triggers if any target becomes unhealthy

### CloudTrail (Optional Enhancement)

Not currently implemented, but recommended for production:
- Log all API calls
- Detect unusual activity
- Compliance and audit requirements
- Integration with AWS Security Hub

---

## Compliance and Best Practices

### AWS Well-Architected Framework

This infrastructure aligns with the Security Pillar:

1. **Identity and Access Management**: IAM roles with least privilege ✓
2. **Detective Controls**: CloudWatch monitoring and logging ✓
3. **Infrastructure Protection**: VPC, security groups, private subnets ✓
4. **Data Protection**: Encryption at rest and in transit ✓
5. **Incident Response**: CloudWatch alarms for detection ✓

### CIS AWS Foundations Benchmark

Alignment with CIS recommendations:
- ✓ Ensure CloudWatch logging is enabled
- ✓ Ensure IAM policies are attached only to groups or roles
- ✓ Ensure security groups restrict access appropriately
- ✓ Ensure VPC flow logs are enabled (future enhancement)
- ✓ Ensure S3 bucket used for Terraform state is encrypted

---

## Security Risks and Mitigations

### Current Risks (Development Environment)

| Risk | Mitigation | Priority |
|------|-----------|----------|
| HTTP only (no HTTPS) | Acceptable for dev; add ACM certificate for prod | High for Prod |
| Single NAT Gateway | Acceptable for dev; multi-NAT for prod HA | Medium |
| Public ALB | Expected; can add WAF for additional protection | Low |
| No VPC Flow Logs | Add for production environments | Medium |
| No WAF | Add for production, especially if public-facing | Medium |

### Mitigations Implemented

1. **Network Isolation**: Private subnets for application instances
2. **Security Group Chaining**: EC2 SG references ALB SG
3. **No SSH Access**: SSM Session Manager only
4. **IAM Least Privilege**: Minimal permissions for EC2 and deployment user
5. **Monitoring**: CloudWatch alarms for anomalies
6. **Encryption**: Data encrypted at rest and in transit (within AWS)

---

## Future Security Enhancements

### For Production Deployment

1. **AWS WAF (Web Application Firewall)**
   - Protect against OWASP Top 10 threats
   - Rate limiting to prevent DDoS
   - Geo-blocking if needed
   - Cost: ~$5-10/month

2. **AWS Shield Standard/Advanced**
   - DDoS protection (Standard included free)
   - Advanced provides enhanced protection
   - Cost: Shield Advanced is $3,000/month (overkill for small apps)

3. **VPC Flow Logs**
   - Log network traffic
   - Detect unusual patterns
   - Security analysis
   - Cost: ~$0.50/GB ingested

4. **AWS GuardDuty**
   - Threat detection service
   - Machine learning for anomaly detection
   - Cost: ~$30/month for this infrastructure

5. **Secrets Manager or Parameter Store**
   - Centralized secrets management
   - Automatic rotation
   - Audit trail
   - Cost: $0.40/secret/month (Secrets Manager)

6. **ACM Certificate for HTTPS**
   - Free SSL/TLS certificates
   - Automatic renewal
   - HTTPS for ALB listeners
   - Cost: Free

7. **KMS Customer-Managed Keys**
   - More control over encryption
   - Key rotation policies
   - Cost: $1/key/month + API costs

8. **Multi-Factor Delete for S3**
   - Prevent accidental deletion of Terraform state
   - Requires MFA for bucket/object deletion

9. **AWS Config**
   - Track resource configuration changes
   - Ensure compliance with policies
   - Cost: ~$2/month

10. **Amazon Inspector**
    - Automated security assessments
    - Vulnerability scanning
    - Cost: ~$0.30/instance/month

---

## Security Incident Response

### Runbook for Security Events

**Suspected Compromise**:
1. Isolate affected instances (modify security groups)
2. Create forensic snapshots of EBS volumes
3. Review CloudWatch logs for unusual activity
4. Check IAM CloudTrail for unauthorized API calls
5. Rotate all credentials (IAM keys, instance profiles)
6. Launch new instances from known-good AMI

**Unusual Traffic Patterns**:
1. Check CloudWatch metrics for spikes
2. Review ALB access logs (if enabled)
3. Verify auto-scaling behavior
4. Check for DDoS attack patterns
5. Consider enabling WAF rate limiting

**Alarm Triggers**:
1. Investigate CloudWatch alarm cause
2. Review application logs in CloudWatch Logs
3. Check EC2 instance health
4. Verify ASG scaling is working correctly
5. Assess if scaling policies need adjustment

---

## Security Checklist

### Pre-Deployment
- [x] IAM user has minimal required permissions
- [x] Security groups follow least-privilege
- [x] EC2 instances in private subnets
- [x] No SSH access configured
- [x] CloudWatch logging enabled
- [ ] Enable default EBS encryption
- [ ] VPC Flow Logs enabled (optional for dev)

### Post-Deployment
- [x] Verify ALB is publicly accessible
- [x] Verify EC2 instances NOT publicly accessible
- [x] Test SSM Session Manager access
- [ ] Set up SNS email notifications
- [ ] Review CloudWatch logs
- [ ] Test application endpoints
- [ ] Verify security group rules
- [ ] Check IAM role is attached to instances

### Production-Specific
- [ ] Enable HTTPS with ACM certificate
- [ ] Configure WAF rules
- [ ] Enable VPC Flow Logs
- [ ] Set up GuardDuty
- [ ] Configure Security Hub
- [ ] Implement multi-NAT Gateway
- [ ] Set up AWS Config rules
- [ ] Enable S3 versioning and MFA Delete
- [ ] Configure KMS customer-managed keys

---

## Conclusion

This infrastructure implements multiple layers of security following AWS best practices:
- **Network isolation** through VPC design
- **Layered security groups** for defense in depth
- **IAM least privilege** for users and resources
- **No SSH access** using Session Manager instead
- **Encryption** for data at rest and in transit
- **Monitoring and logging** for audit trails

The IAM user deploying this infrastructure has restricted permissions following the principle of least privilege, demonstrating security-conscious design even for development environments.

While suitable for development, production deployments should implement additional security measures including HTTPS, WAF, enhanced monitoring, and more rigorous access controls.
