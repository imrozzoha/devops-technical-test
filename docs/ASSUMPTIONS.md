# Assumptions Document

This document outlines the assumptions made during the design and implementation of this AWS infrastructure project.

## Regional Configuration

### AWS Region
- **Region**: ap-southeast-2 (Sydney)
- **Reason**: Specified in requirements
- **Availability Zones**: ap-southeast-2a and ap-southeast-2b
- **Impact**: All resources deployed in this region

## Traffic and Scaling Assumptions

### Traffic Pattern
- **Expected Load**: 1 million requests per month
- **Distribution**: Evenly distributed throughout the month
- **Calculation**: ~1.4 requests per minute average
- **Peak Traffic**: No significant peak hours assumed
- **Geographic Source**: Primarily from Australia/Asia-Pacific region

### Scaling Requirements
- **Baseline Capacity**: 2 instances sufficient for normal load
- **Peak Capacity**: 4 instances sufficient for 2x traffic spikes
- **CPU Target**: 70% utilization balances cost and responsiveness
- **Growth**: No rapid growth expected in development phase

## Network and Connectivity

### SSL/TLS
- **HTTPS**: Not required for development environment
- **HTTP Only**: All traffic on port 80
- **Certificate**: No ACM certificate needed
- **Justification**: Reduces complexity in development; production would require HTTPS

### DNS
- **Custom Domain**: Not required
- **Access Method**: ALB DNS name (e.g., devops-test-dev-alb-123456789.ap-southeast-2.elb.amazonaws.com)
- **Route53**: Not configured
- **Justification**: Development environment doesn't need custom domain

### Internet Access for EC2
- **Direct Access**: EC2 instances do not need direct internet connectivity
- **Outbound Access**: Via NAT Gateway for package updates and AWS API calls
- **Inbound Access**: Only through ALB
- **Justification**: Enhanced security through network isolation

## High Availability vs Cost Trade-offs

### Single NAT Gateway
- **Configuration**: One NAT Gateway in ap-southeast-2a
- **Cost**: ~$33/month for single gateway vs ~$66/month for dual
- **Risk**: If ap-southeast-2a fails, private subnet instances lose internet access
- **Mitigation**: This is acceptable for development; production should use multi-NAT
- **Impact**: Can't update packages or call AWS APIs during AZ failure

### No Multi-Region Deployment
- **Configuration**: Single region deployment
- **Reason**: Development environment doesn't require global distribution
- **Disaster Recovery**: Manual rebuild from Terraform in another region if needed
- **Justification**: Multi-region adds significant complexity and cost

## Infrastructure as Code

### State Management
- **Backend**: S3 bucket with DynamoDB locking
- **State File**: Shared state for team collaboration
- **Assumption**: Backend bucket already created (via backend-config.env)
- **Encryption**: State file encrypted at rest in S3

### Existing Infrastructure
- **Clean Slate**: No existing VPC infrastructure in the account
- **No Conflicts**: No CIDR block conflicts with existing networks
- **Default VPC**: May exist but not used
- **Peering**: No VPC peering required

## Security Assumptions

### IAM Permissions
- **IAM User**: Has restricted permissions following least-privilege principle
- **Permissions Include**:
  - EC2, VPC, ELB management
  - IAM role/policy creation
  - CloudWatch logs and alarms
  - S3 state bucket access
  - DynamoDB state lock access
- **No Admin Access**: User does not have full administrative permissions
- **MFA**: Assumed to be enabled for IAM user (best practice)

### SSH Access
- **SSH Keys**: Not required or configured
- **Access Method**: AWS Systems Manager Session Manager
- **Assumption**: Session Manager sufficient for troubleshooting
- **Justification**: Eliminates SSH key management and improves security

### Security Group Rules
- **Inbound HTTP**: Accepted from any source (0.0.0.0/0) on ALB
- **Assumption**: Application is meant to be publicly accessible
- **Future**: Could restrict to specific IP ranges or integrate with WAF

## Data and Storage

### Log Retention
- **Period**: 7 days
- **Reason**: Development-grade retention to minimize costs
- **Production**: Would use 30-90 days or longer for compliance
- **Cost Impact**: Longer retention increases CloudWatch Logs costs

### Data Persistence
- **Application State**: Stateless application (no database required)
- **Session Management**: No session stickiness configured
- **User Data**: No persistent user data
- **Assumption**: Simple request/response application with no state

### EBS Volumes
- **Type**: Default EBS volumes from Amazon Linux 2023 AMI
- **Size**: 8 GB root volume
- **Encryption**: Default encryption (should be enabled in AWS account settings)
- **Backup**: No automated snapshots (development environment)

## Operational Assumptions

### Deployment Frequency
- **Updates**: Infrequent updates expected in development
- **Deployment Method**: Launch template update + instance refresh
- **Downtime**: Brief downtime acceptable during deployments
- **Blue/Green**: Not implemented (simple replacement strategy)

### Monitoring and Alerting
- **SNS Notifications**: Topic created but no email subscriptions
- **Assumption**: Email subscriptions added manually or via separate process
- **On-Call**: No formal on-call process for development environment
- **Response Time**: Not critical for development

### Business Hours
- **Availability**: 24/7 operation assumed
- **Maintenance Windows**: No scheduled maintenance windows
- **Auto Scaling**: Active at all times
- **Cost**: Instances run continuously (no scheduled shutdowns)

## Application Assumptions

### Application Code
- **Language**: Node.js (version 18.x)
- **Dependencies**: No external npm packages required
- **Startup Time**: Fast startup (<30 seconds)
- **Resource Usage**: Minimal CPU and memory footprint

### Health Checks
- **Endpoint**: /health returns "healthy" and HTTP 200
- **Reliability**: Endpoint always responds if application is running
- **No Dependencies**: Health check doesn't check external dependencies
- **Simplicity**: Binary health status (healthy or not)

### Application Logs
- **Location**: /var/log/app.log
- **Format**: Plain text (not structured JSON)
- **Rotation**: No log rotation configured (7-day CloudWatch retention handles cleanup)
- **Assumption**: Log volume low enough to not fill disk

## Cost Assumptions

### AWS Pricing
- **Region**: ap-southeast-2 (Sydney) pricing used
- **Free Tier**: Not factored in (assume post-free-tier pricing)
- **Reserved Instances**: Not used (on-demand pricing)
- **Spot Instances**: Not used (for simplicity and reliability)

### Usage Patterns
- **Steady State**: 2 instances running 24/7
- **Scaling Events**: Infrequent scaling to 3-4 instances
- **Data Transfer**: Minimal outbound data transfer
- **API Calls**: Standard API usage for health checks and monitoring

## Environment Classification

### Development Environment
- **Purpose**: Testing and development
- **SLA**: No formal SLA
- **Compliance**: No compliance requirements (HIPAA, PCI-DSS, etc.)
- **Data Sensitivity**: No sensitive or production data
- **Justification**: Allows for relaxed security and cost optimization

### Future Environments
- **Staging**: Would mirror production architecture
- **Production**: Would include:
  - Multi-NAT Gateway configuration
  - Longer log retention
  - HTTPS with ACM certificate
  - WAF integration
  - Reserved Instances
  - Stricter security controls
  - Enhanced monitoring and alerting

## Technical Constraints

### Amazon Linux 2023
- **Choice**: Latest Amazon Linux AMI
- **Assumption**: Compatible with Node.js 18.x
- **Updates**: Regular security patches via yum update
- **Support**: Long-term support from AWS

### Instance Type
- **t3.micro**: Assumed sufficient for low-traffic application
- **Burstable**: CPU credits assumed adequate for traffic pattern
- **Baseline Performance**: 10% baseline CPU performance acceptable
- **Upgrade Path**: Can upgrade to t3.small or larger if needed

## External Dependencies

### NodeSource Repository
- **Assumption**: NodeSource repository for Node.js 18.x is available and reliable
- **Risk**: If repository is down, instance bootstrap fails
- **Mitigation**: Could build custom AMI with Node.js pre-installed

### AWS Service Availability
- **Assumption**: AWS services (EC2, ALB, CloudWatch) are available and functioning
- **Dependency**: Infrastructure relies on AWS service health
- **Risk Acceptance**: Standard AWS SLA applies

## Documentation and Knowledge

### Team Skills
- **Terraform**: Team familiar with Terraform and HCL syntax
- **AWS**: Team understands AWS services and architecture
- **Linux**: Team comfortable with Linux administration
- **Node.js**: Basic Node.js knowledge for troubleshooting

### Runbooks
- **Assumption**: Team will develop operational runbooks as needed
- **Documentation**: This project includes comprehensive documentation
- **Knowledge Transfer**: Code and documentation sufficient for knowledge transfer
