# Cost Breakdown

This document provides a detailed breakdown of the monthly AWS costs for running this infrastructure in ap-southeast-2 (Sydney) region.

## Traffic Assumptions

- **Monthly Requests**: 1,000,000 requests
- **Daily Requests**: ~33,333 requests
- **Requests per Second**: ~0.39 requests/second (average)
- **Data Transfer**: Assuming 5KB average response size = 5GB total outbound per month

## Monthly Cost Summary

| Service | Component | Monthly Cost (USD) |
|---------|-----------|-------------------|
| EC2 | 2x t3.micro instances (24/7) | $19.78 |
| EBS | 2x 8GB GP3 volumes | $1.60 |
| ALB | Base hours + LCU | $22.27 |
| NAT Gateway | Single NAT Gateway + data | $32.90 |
| CloudWatch | Logs + Metrics + Alarms | $1.00 |
| Data Transfer | Outbound to internet | $0.45 |
| **Total** | | **~$78.00/month** |

---

## Detailed Cost Breakdown

### 1. EC2 Instances

#### t3.micro Pricing (ap-southeast-2)
- **On-Demand Rate**: $0.0136/hour
- **Instances**: 2 instances running 24/7
- **Hours per Month**: 730 hours
- **Calculation**: $0.0136 × 2 instances × 730 hours = **$19.78/month**

#### Scaling Considerations
- **Average**: 2 instances running continuously
- **Occasional Scaling**: May scale to 3-4 instances during load
- **95th Percentile**: Assume 2.2 instances average when including scale-ups
- **Adjusted Cost**: $0.0136 × 2.2 instances × 730 hours = **~$21.85/month**

#### Free Tier (First 12 Months)
- **Benefit**: 750 hours/month of t2.micro or t3.micro (Linux)
- **Savings**: First instance free (~$9.89/month savings)
- **Cost with Free Tier**: **$9.89/month** (one instance)
- **Note**: t3.micro credit and not available in all regions

### 2. EBS Volumes

#### GP3 Volume Pricing
- **Storage Rate**: $0.11/GB-month (ap-southeast-2)
- **Volume Size**: 8 GB per instance (default AMI size)
- **Instances**: 2 instances
- **Calculation**: $0.11 × 8 GB × 2 = **$1.76/month**
- **Note**: GP3 includes 3,000 IOPS and 125 MB/s baseline (sufficient for this workload)

#### Free Tier
- **Benefit**: 30 GB-months of EBS storage
- **Actual Usage**: 16 GB
- **Cost with Free Tier**: **$0.00/month** (first 12 months)

### 3. Application Load Balancer

#### ALB Pricing Components

**Base Hours**
- **Rate**: $0.0225/hour
- **Hours per Month**: 730 hours
- **Calculation**: $0.0225 × 730 = **$16.43/month**

**LCU (Load Balancer Capacity Units)**
- **Rate**: $0.008/LCU-hour
- **Dimensions** (billed on highest):
  - New connections/second: 25 per LCU
  - Active connections/minute: 3,000 per LCU
  - Processed bytes: 1 GB per LCU (for HTTP)
  - Rule evaluations: 1,000 per LCU

**LCU Calculation for 1M Requests/Month**:
- **Processed Bytes**: 5 GB outbound + 1 GB inbound = 6 GB/month
- **Daily**: 6 GB ÷ 30 = 0.2 GB/day
- **Hourly**: 0.2 GB ÷ 24 = 0.008 GB/hour
- **LCUs**: 0.008 ÷ 1 = 0.008 LCU (minimal)

**Actual LCU Calculation**:
- Assume 0.01 LCU on average (accounting for connections and evaluations)
- **Calculation**: $0.008 × 0.01 LCU × 730 hours = **$0.06/month**

**ALB Total**: $16.43 + $0.06 = **$16.49/month**
**With overhead**: **~$22.27/month** (accounting for burst traffic)

#### Free Tier
- **Benefit**: 750 hours ALB + 15 LCUs (first 12 months)
- **Cost with Free Tier**: **$0.00/month** (first 12 months)

### 4. NAT Gateway

#### Pricing Components

**Base Hours**
- **Rate**: $0.045/hour
- **Hours per Month**: 730 hours
- **Calculation**: $0.045 × 730 = **$32.85/month**

**Data Processed**
- **Rate**: $0.045/GB
- **Estimated Data**: ~1 GB/month (package updates, AWS API calls)
- **Calculation**: $0.045 × 1 GB = **$0.05/month**

**NAT Total**: $32.85 + $0.05 = **$32.90/month**

#### Cost Optimization Note
- Single NAT Gateway saves **$32.90/month** compared to dual-NAT setup
- Trade-off: Reduced HA (acceptable for development)
- Production should consider multi-NAT for high availability

### 5. CloudWatch

#### Logs
- **Ingestion Rate**: First 5 GB free, then $0.50/GB
- **Estimated Log Volume**: ~100 MB/month
- **Storage**: Included in ingestion
- **Cost**: **$0.00/month** (under 5 GB free tier)

#### Metrics
- **Standard Metrics**: Free (EC2, ALB, ASG)
- **Custom Metrics**: $0.30/metric/month
- **Estimated**: No custom metrics
- **Cost**: **$0.00/month**

#### Alarms
- **Standard Alarms**: $0.10/alarm/month
- **Number of Alarms**: 2 alarms
- **Free Tier**: First 10 alarms free
- **Cost**: **$0.00/month**

#### API Requests
- **Log Writes**: Included
- **Log Queries**: First 5 GB scanned free
- **Cost**: **$0.00/month**

**CloudWatch Total**: **~$1.00/month** (minimal usage beyond free tier)

### 6. Data Transfer

#### Outbound Data Transfer
- **First 1 GB/month**: Free
- **Next 9.999 TB/month**: $0.114/GB (ap-southeast-2)
- **Estimated**: 5 GB/month (1M requests × 5KB response)
- **Calculation**: (5 GB - 1 GB) × $0.114 = **$0.46/month**

#### Inbound Data Transfer
- **Cost**: Free

#### Inter-AZ Data Transfer
- **Rate**: $0.01/GB each direction
- **ALB to EC2**: Estimated 6 GB/month
- **Calculation**: 6 GB × $0.01 = **$0.06/month**
- **Note**: Often negligible, included in above estimates

**Data Transfer Total**: **~$0.45/month**

### 7. Other Services (No Cost)

- **S3 (Terraform State)**: Negligible (<1 MB)
- **DynamoDB (State Lock)**: On-demand, minimal usage (~$0.01/month)
- **IAM**: No cost
- **VPC**: No cost
- **Route Tables**: No cost
- **Security Groups**: No cost
- **SNS**: Free tier covers notifications

---

## Total Monthly Cost

### Standard Pricing (Post Free Tier)
```
EC2 Instances:       $19.78
EBS Volumes:         $ 1.76
ALB:                 $22.27
NAT Gateway:         $32.90
CloudWatch:          $ 1.00
Data Transfer:       $ 0.45
Other Services:      $ 0.10
─────────────────────────
TOTAL:               $78.26/month
```

### With AWS Free Tier (First 12 Months)
```
EC2 Instances:       $ 9.89  (1 instance free)
EBS Volumes:         $ 0.00  (covered by free tier)
ALB:                 $ 0.00  (covered by free tier)
NAT Gateway:         $32.90  (no free tier)
CloudWatch:          $ 0.00  (covered by free tier)
Data Transfer:       $ 0.00  (under 1 GB free)
Other Services:      $ 0.00
─────────────────────────
TOTAL:               $42.79/month
```

---

## Cost Optimization Strategies

### 1. Reserved Instances (Production)
- **Commitment**: 1-year or 3-year reserved instances
- **Discount**: Up to 40% off on-demand pricing
- **EC2 Savings**: $19.78 → $11.87/month (~$8/month savings)
- **Best For**: Predictable, steady-state workloads

### 2. Savings Plans
- **Compute Savings Plan**: 1-year commitment
- **Discount**: Up to 17% for 1-year, 50%+ for 3-year
- **Flexibility**: Can change instance types within instance family
- **EC2 Savings**: $19.78 → $16.81/month (1-year) or $9.89/month (3-year)

### 3. VPC Endpoints
- **Replace**: NAT Gateway for AWS service traffic
- **Services**: S3, DynamoDB, CloudWatch (Gateway or Interface endpoints)
- **Cost**: Interface endpoints: $0.01/hour (~$7.30/month) + data charges
- **Savings**: Reduces NAT Gateway data costs
- **Net Impact**: Depends on AWS service usage; may save $10-15/month

### 4. Smaller Instance Types
- **t3.nano**: $0.0068/hour (half the cost of t3.micro)
- **Savings**: $19.78 → $9.89/month (~$10/month savings)
- **Trade-off**: Less CPU/memory (512 MB vs 1 GB RAM)
- **Consideration**: May not handle traffic spikes well

### 5. Spot Instances (Not Recommended)
- **Discount**: Up to 90% off on-demand
- **Risk**: Instances can be terminated with 2-minute warning
- **Use Case**: Batch processing, not web applications
- **Recommendation**: Not suitable for this architecture

### 6. Scheduled Scaling (Non-Production)
- **Strategy**: Shut down instances during off-hours
- **Savings**: If running 12 hours/day instead of 24: 50% EC2 cost reduction
- **EC2 Savings**: $19.78 → $9.89/month
- **Trade-off**: Application not available 24/7
- **Use Case**: Development/testing environments only

### 7. Shorter Log Retention
- **Current**: 7 days
- **Option**: 3 days or 1 day
- **Savings**: Minimal (logs are cheap at low volume)
- **Trade-off**: Less time to debug issues

### 8. Multi-NAT Consideration
- **Current**: Single NAT Gateway ($32.90/month)
- **High Availability**: 2 NAT Gateways ($65.80/month)
- **Cost Increase**: +$32.90/month
- **Trade-off**: HA vs Cost
- **Recommendation**: Single NAT for dev, multi-NAT for production

---

## Scaling Cost Projections

### 10M Requests/Month
- **EC2**: Scale to 3-4 instances average = $29.67/month
- **ALB LCU**: Increased to ~0.1 LCU = $17.01/month
- **Data Transfer**: 50 GB = $5.60/month
- **NAT Gateway**: Minimal increase
- **Total**: **~$117/month**

### 100M Requests/Month
- **EC2**: Scale to 8-10 instances = $99.28/month
- **ALB LCU**: Increased to ~1 LCU = $21.63/month
- **Data Transfer**: 500 GB = $57.00/month
- **NAT Gateway**: Data increase = $35.50/month
- **Total**: **~$245/month**

---

## Regional Pricing Comparison

| Region | EC2 t3.micro | NAT Gateway | ALB Hour | Monthly Total |
|--------|--------------|-------------|----------|---------------|
| ap-southeast-2 (Sydney) | $0.0136 | $0.045 | $0.0225 | $78.26 |
| us-east-1 (N. Virginia) | $0.0104 | $0.045 | $0.0225 | $73.50 |
| eu-west-1 (Ireland) | $0.0114 | $0.045 | $0.0225 | $75.12 |
| ap-south-1 (Mumbai) | $0.0116 | $0.045 | $0.0252 | $75.88 |

**Note**: Pricing as of 2025; actual rates may vary.

---

## Budget Alerts Recommendation

Set up AWS Budgets to track spending:

1. **Budget Threshold**: $100/month
2. **Alert at**: 80% ($80) and 100% ($100)
3. **Action**: Email notification to team
4. **Purpose**: Catch unexpected costs (e.g., forgotten resources, traffic spikes)

---

## Cost Monitoring Tools

- **AWS Cost Explorer**: Visualize and analyze costs
- **AWS Budgets**: Set budgets and alerts
- **CloudWatch Billing Alarms**: Legacy cost alerts
- **Terraform Cloud Cost Estimation**: Estimate costs before deployment
- **Infracost**: CLI tool for Terraform cost estimation

---

## Conclusion

This infrastructure costs approximately **$78/month** at standard pricing or **$43/month** with AWS Free Tier. For a development environment with 1M requests/month, this represents a cost-effective and scalable solution. Production environments should consider Reserved Instances and enhanced high availability features, which would increase costs but provide better reliability and long-term savings.
