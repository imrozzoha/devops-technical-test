# Deployment Guide

This guide provides step-by-step instructions for deploying the AWS infrastructure using Terraform on Windows with PowerShell.

## Prerequisites

### Required Tools

1. **AWS CLI** (v2.x or later)
   ```powershell
   # Check version
   aws --version

   # Should output: aws-cli/2.x.x Python/3.x.x Windows/...
   ```

2. **Terraform** (v1.0 or later)
   ```powershell
   # Check version
   terraform version

   # Should output: Terraform v1.x.x
   ```

3. **Git** (for version control)
   ```powershell
   # Check version
   git --version
   ```

4. **PowerShell** (v5.1 or later)
   ```powershell
   # Check version
   $PSVersionTable.PSVersion
   ```

### AWS Configuration

1. **AWS Credentials**
   - IAM user with restricted permissions following least-privilege principle
   - Required permissions: EC2, VPC, ELB, IAM, CloudWatch, S3, DynamoDB
   - Configure AWS CLI:
   ```powershell
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (ap-southeast-2), Output (json)
   ```

2. **Verify AWS Access**
   ```powershell
   aws sts get-caller-identity
   ```
   Should return your AWS account ID and IAM user ARN.

### Backend Setup

The Terraform backend (S3 bucket and DynamoDB table) should already be configured. Verify:

```powershell
# Check if backend-config.env exists
Get-Content backend-config.env
```

Expected content:
```
TERRAFORM_BACKEND_BUCKET=devops-test-tfstate-XXXXXXXXXX
TERRAFORM_BACKEND_TABLE=devops-test-terraform-locks
TERRAFORM_BACKEND_REGION=ap-southeast-2
```

---

## Deployment Steps

### Step 1: Clone Repository (if not already done)

```powershell
git clone <repository-url>
cd devops-technical-test
```

### Step 2: Review Configuration

```powershell
# Review the environment variables
Get-Content terraform\environments\dev\terraform.tfvars
```

Verify the configuration matches your requirements:
- Region: ap-southeast-2
- VPC CIDR: 10.0.0.0/16
- Instance type: t3.micro
- ASG sizing: min=2, max=4, desired=2

### Step 3: Initialize Terraform

```powershell
# Navigate to terraform directory
cd terraform

# Parse backend config
$backendConfig = @{}
Get-Content ..\backend-config.env | ForEach-Object {
    if ($_ -match '(.+)=(.+)') {
        $key = $matches[1].ToLower().Replace('terraform_backend_', '')
        $value = $matches[2]
        $backendConfig[$key] = $value
    }
}

# Initialize Terraform with backend configuration
terraform init `
    -backend-config="bucket=$($backendConfig.bucket)" `
    -backend-config="key=devops-test/dev/terraform.tfstate" `
    -backend-config="region=$($backendConfig.region)" `
    -backend-config="dynamodb_table=$($backendConfig.table)" `
    -backend-config="encrypt=true"
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```powershell
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 5: Create Execution Plan

```powershell
# Create plan
terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan

# View plan summary
terraform show tfplan
```

Review the plan output carefully. Terraform should show:
- **Resources to create**: ~30-35 resources
- **Resources to change**: 0
- **Resources to destroy**: 0

Key resources to verify:
- VPC and subnets (6 subnets total)
- Internet Gateway and NAT Gateway
- Security groups (2)
- IAM role and instance profile
- Application Load Balancer and target group
- Launch template and Auto Scaling Group
- CloudWatch log group and alarms

### Step 6: Apply the Plan

**IMPORTANT**: Before applying, ensure you have:
- Reviewed the plan output
- Verified costs align with expectations (~$78/month)
- Confirmed backend is properly configured
- Obtained necessary approvals

```powershell
# Apply the plan
terraform apply tfplan
```

The deployment will take approximately **10-15 minutes**. Terraform will:
1. Create VPC and networking (2-3 min)
2. Create security groups and IAM resources (1 min)
3. Create NAT Gateway (3-5 min)
4. Create ALB (2-3 min)
5. Create ASG and launch instances (5-7 min)
6. Wait for health checks to pass

### Step 7: Capture Outputs

```powershell
# Display outputs
terraform output

# Save outputs to file
terraform output > ..\deployment-outputs.txt

# Display specific outputs
terraform output alb_dns_name
terraform output application_url
```

Example output:
```
alb_dns_name = "devops-test-dev-alb-1234567890.ap-southeast-2.elb.amazonaws.com"
application_url = "http://devops-test-dev-alb-1234567890.ap-southeast-2.elb.amazonaws.com/hello"
```

---

## Testing the Deployment

### Test 1: Application Endpoint

```powershell
# Get the ALB DNS name
$albDns = terraform output -raw alb_dns_name

# Test /hello endpoint
$response = Invoke-WebRequest -Uri "http://$albDns/hello" -UseBasicParsing
Write-Host "Status: $($response.StatusCode)"
Write-Host "Body: $($response.Content)"
```

Expected output:
```
Status: 200
Body: OK
```

### Test 2: Health Check Endpoint

```powershell
# Test /health endpoint
$response = Invoke-WebRequest -Uri "http://$albDns/health" -UseBasicParsing
Write-Host "Status: $($response.StatusCode)"
Write-Host "Body: $($response.Content)"
```

Expected output:
```
Status: 200
Body: healthy
```

### Test 3: Load Testing (Optional)

```powershell
# Simple load test - 100 requests
1..100 | ForEach-Object -Parallel {
    Invoke-WebRequest -Uri "http://$using:albDns/hello" -UseBasicParsing | Out-Null
    Write-Host "Request $_ completed"
} -ThrottleLimit 10
```

### Test 4: Multiple Requests

```powershell
# Test multiple requests in sequence
$url = "http://$albDns/hello"
for ($i = 1; $i -le 10; $i++) {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    Write-Host "Request $i : Status $($response.StatusCode)"
}
```

---

## Verification Steps

### 1. AWS Console Verification

**EC2 Instances**:
```powershell
# List running instances
aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=devops-test" "Name=instance-state-name,Values=running" `
    --query "Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]" `
    --output table
```

**Load Balancer**:
```powershell
# Describe ALB
aws elbv2 describe-load-balancers `
    --names "devops-test-dev-alb" `
    --query "LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]" `
    --output table
```

**Target Health**:
```powershell
# Get target group ARN
$tgArn = aws elbv2 describe-target-groups `
    --names "devops-test-dev-tg" `
    --query "TargetGroups[0].TargetGroupArn" `
    --output text

# Check target health
aws elbv2 describe-target-health `
    --target-group-arn $tgArn `
    --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]" `
    --output table
```

Expected: Both targets should show `healthy` state.

### 2. CloudWatch Logs

```powershell
# List log streams
aws logs describe-log-streams `
    --log-group-name "/aws/ec2/devops-test-dev" `
    --order-by LastEventTime `
    --descending `
    --max-items 5 `
    --query "logStreams[*].[logStreamName,lastEventTime]" `
    --output table
```

### 3. Auto Scaling Group

```powershell
# Describe ASG
aws autoscaling describe-auto-scaling-groups `
    --auto-scaling-group-names "devops-test-dev-asg" `
    --query "AutoScalingGroups[*].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize,Instances[*].InstanceId]" `
    --output json
```

### 4. CloudWatch Alarms

```powershell
# List alarms
aws cloudwatch describe-alarms `
    --alarm-name-prefix "devops-test-dev" `
    --query "MetricAlarms[*].[AlarmName,StateValue,MetricName]" `
    --output table
```

---

## Troubleshooting

### Issue 1: Terraform Init Fails

**Error**: `Error configuring S3 Backend: NoSuchBucket`

**Solution**:
```powershell
# Verify backend config
Get-Content ..\backend-config.env

# Check if S3 bucket exists
$bucket = (Get-Content ..\backend-config.env | Select-String "BUCKET" | ForEach-Object {$_ -replace ".*=",""}).Trim()
aws s3 ls "s3://$bucket"
```

### Issue 2: Health Checks Failing

**Error**: Targets show `unhealthy` in target group

**Solution**:
```powershell
# Check security group rules
aws ec2 describe-security-groups `
    --filters "Name=tag:Name,Values=devops-test-dev-ec2-sg" `
    --query "SecurityGroups[*].IpPermissions" `
    --output json

# Connect to instance via SSM and check application
$instanceId = (aws ec2 describe-instances `
    --filters "Name=tag:Project,Values=devops-test" "Name=instance-state-name,Values=running" `
    --query "Reservations[0].Instances[0].InstanceId" `
    --output text)

# Start SSM session (requires AWS Session Manager plugin)
aws ssm start-session --target $instanceId
```

Once connected to instance:
```bash
# Check if app is running
sudo systemctl status app

# Check app logs
sudo tail -f /var/log/app.log

# Test locally
curl http://localhost:8080/hello
```

### Issue 3: Application Not Responding

**Error**: Connection timeout or 503 error

**Solution**:
```powershell
# Wait for instances to fully boot (may take 5-10 minutes)
Start-Sleep -Seconds 60

# Check target health again
$tgArn = aws elbv2 describe-target-groups `
    --names "devops-test-dev-tg" `
    --query "TargetGroups[0].TargetGroupArn" `
    --output text

aws elbv2 describe-target-health --target-group-arn $tgArn
```

### Issue 4: Terraform Apply Fails

**Error**: `Error creating resource: InsufficientPermissions`

**Solution**:
Verify IAM user has required permissions. The IAM user should have restricted permissions following least-privilege, but must include:
- EC2 full access (for instances, VPC, etc.)
- IAM role/policy creation
- ELB full access
- CloudWatch logs/metrics/alarms
- S3 access to state bucket
- DynamoDB access to lock table

### Issue 5: NAT Gateway Creation Timeout

**Error**: `Error waiting for NAT Gateway to become available`

**Solution**:
NAT Gateways can take 5-10 minutes to provision. If timeout occurs:
```powershell
# Check NAT Gateway status
aws ec2 describe-nat-gateways `
    --filter "Name=tag:Name,Values=devops-test-dev-nat-gw" `
    --query "NatGateways[*].[NatGatewayId,State]" `
    --output table
```

If stuck in "pending", wait a few more minutes. If "failed", destroy and retry:
```powershell
terraform destroy -var-file="environments/dev/terraform.tfvars" -auto-approve
terraform apply -var-file="environments/dev/terraform.tfvars"
```

---

## Post-Deployment Configuration

### Set Up SNS Email Notifications (Optional)

```powershell
# Get SNS topic ARN
$topicArn = terraform output -raw sns_topic_arn

# Subscribe email to SNS topic
aws sns subscribe `
    --topic-arn $topicArn `
    --protocol email `
    --notification-endpoint your-email@example.com

# Confirm subscription via email
```

### Configure CloudWatch Dashboard (Optional)

Create a custom dashboard to visualize metrics:
```powershell
# This can be done via AWS Console or AWS CLI
# Navigate to CloudWatch > Dashboards > Create dashboard
```

---

## Updating the Infrastructure

### Modify Configuration

```powershell
# Edit terraform.tfvars
notepad terraform\environments\dev\terraform.tfvars

# For example, change instance type:
# instance_type = "t3.small"
```

### Apply Changes

```powershell
cd terraform

# Plan changes
terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan

# Review what will change
terraform show tfplan

# Apply changes
terraform apply tfplan
```

---

## Cleanup/Teardown

### Option 1: Using Cleanup Script

```powershell
# From project root
.\scripts\cleanup.ps1
```

### Option 2: Manual Terraform Destroy

```powershell
cd terraform

# Destroy infrastructure
terraform destroy -var-file="environments/dev/terraform.tfvars"

# Type 'yes' when prompted
```

**Note**: This will destroy all infrastructure but keep the S3 state bucket and DynamoDB table.

### Option 3: Destroy Everything Including Backend

```powershell
# First destroy infrastructure
cd terraform
terraform destroy -var-file="environments/dev/terraform.tfvars" -auto-approve

# Then destroy backend (BE CAREFUL - this deletes state!)
cd ..
$bucket = (Get-Content backend-config.env | Select-String "BUCKET" | ForEach-Object {$_ -replace ".*=",""}).Trim()
$table = (Get-Content backend-config.env | Select-String "TABLE" | ForEach-Object {$_ -replace ".*=",""}).Trim()

# Delete S3 bucket and all contents
aws s3 rb "s3://$bucket" --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name $table
```

---

## Cost Monitoring

### Set Up Billing Alert

```powershell
# Create SNS topic for billing alerts
aws sns create-topic --name billing-alerts

# Subscribe to topic
aws sns subscribe `
    --topic-arn <topic-arn> `
    --protocol email `
    --notification-endpoint your-email@example.com

# Create CloudWatch billing alarm (in us-east-1)
aws cloudwatch put-metric-alarm `
    --alarm-name "MonthlyBudget-100USD" `
    --alarm-description "Alert when monthly charges exceed $100" `
    --metric-name EstimatedCharges `
    --namespace AWS/Billing `
    --statistic Maximum `
    --period 21600 `
    --evaluation-periods 1 `
    --threshold 100 `
    --comparison-operator GreaterThanThreshold `
    --alarm-actions <sns-topic-arn> `
    --region us-east-1
```

### Check Current Costs

```powershell
# Get month-to-date costs (requires Cost Explorer API enabled)
aws ce get-cost-and-usage `
    --time-period Start=2025-12-01,End=2025-12-31 `
    --granularity MONTHLY `
    --metrics "UnblendedCost" `
    --region us-east-1
```

---

## Best Practices

1. **Always review the plan** before applying changes
2. **Use version control** for all Terraform configuration changes
3. **Test in development** before deploying to production
4. **Monitor costs** regularly using AWS Cost Explorer
5. **Set up alerts** for infrastructure and billing
6. **Document changes** in commit messages
7. **Use workspaces** for multiple environments (dev, staging, prod)
8. **Backup state files** (handled by S3 versioning)
9. **Use variables** instead of hardcoded values
10. **Tag all resources** for cost allocation and organization

---

## Support and Resources

- **Terraform Documentation**: https://www.terraform.io/docs
- **AWS CLI Reference**: https://docs.aws.amazon.com/cli/
- **AWS Architecture Best Practices**: https://aws.amazon.com/architecture/well-architected/
- **Project Documentation**: See docs/ directory for additional guides

---

## Appendix: Command Reference

### Terraform Commands
```powershell
terraform init          # Initialize working directory
terraform fmt           # Format code
terraform validate      # Validate configuration
terraform plan          # Create execution plan
terraform apply         # Apply changes
terraform destroy       # Destroy infrastructure
terraform output        # Show outputs
terraform state list    # List resources in state
terraform state show    # Show resource details
```

### AWS CLI Commands
```powershell
aws ec2 describe-instances              # List EC2 instances
aws elbv2 describe-load-balancers       # List load balancers
aws autoscaling describe-auto-scaling-groups  # List ASGs
aws logs tail <log-group> --follow      # Tail CloudWatch logs
aws ssm start-session --target <id>     # Start SSM session
```

---

## Next Steps

After successful deployment:

1. Review ARCHITECTURE.md for detailed architecture information
2. Review COST_BREAKDOWN.md for cost optimization strategies
3. Review SECURITY.md for security best practices
4. Set up monitoring and alerting
5. Document any environment-specific configurations
6. Plan for production deployment with enhanced HA features
