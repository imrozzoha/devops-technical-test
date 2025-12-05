# Monitoring Module

This module creates CloudWatch monitoring resources including log groups, alarms, and SNS topics for notifications.

## Components

### CloudWatch Log Group
- **Name**: `/aws/ec2/devops-test-dev`
- **Retention**: 7 days (configurable, set low for development to reduce costs)
- **Purpose**: Stores application logs from EC2 instances

### SNS Topic
- **Name**: `devops-test-dev-alarms`
- **Purpose**: Destination for CloudWatch alarm notifications
- **Note**: No email subscriptions configured in this basic setup

### CloudWatch Alarms

#### High CPU Utilization Alarm
- **Metric**: Average CPU Utilization across ASG
- **Threshold**: > 80%
- **Evaluation**: 2 consecutive periods (10 minutes total)
- **Period**: 5 minutes
- **Action**: Publish to SNS topic
- **Purpose**: Alert when instances are under sustained high load

#### Unhealthy Targets Alarm
- **Metric**: Unhealthy host count in target group
- **Threshold**: > 0
- **Evaluation**: 1 period (1 minute)
- **Period**: 1 minute
- **Action**: Publish to SNS topic
- **Purpose**: Alert immediately when health checks fail

## Design Decisions

### Short Log Retention
The 7-day retention period is suitable for development environments and significantly reduces costs. Production environments should use 30+ days.

### Alarm Thresholds
- **CPU Alarm**: Set at 80% instead of the scaling threshold (70%) to alert on sustained high load that might require attention
- **Unhealthy Targets**: Set to alert on any unhealthy target for immediate visibility into health issues

### SNS Without Subscriptions
The SNS topic is created but subscriptions are not configured via Terraform to avoid storing email addresses in code. Subscriptions can be added manually or via a separate process.

## Metrics Available

Additional metrics automatically available for monitoring:
- **ALB**: Request count, response time, HTTP error codes
- **EC2**: CPU, network, disk I/O
- **ASG**: Instance counts, scaling activities

## Cost Considerations

- **CloudWatch Logs**: First 5 GB ingested per month is free, then $0.50/GB
- **CloudWatch Metrics**: Basic monitoring is free, detailed monitoring costs apply
- **Alarms**: First 10 alarms are free, then $0.10/alarm/month
- **SNS**: First 1M notifications free, then $0.50/million

For this setup with minimal traffic:
- Logs: ~$0.50/month
- Metrics: Included in EC2 costs
- Alarms: Free (2 alarms)
- SNS: Free
- **Total**: ~$0.50-$1.00/month

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name for resource naming | string | required |
| environment | Environment name | string | required |
| log_retention_days | CloudWatch log retention in days | number | 7 |
| asg_name | Name of the ASG to monitor | string | required |
| alb_arn_suffix | ARN suffix of the ALB | string | required |
| target_group_arn_suffix | ARN suffix of the target group | string | required |

## Outputs

| Name | Description |
|------|-------------|
| log_group_name | Name of the CloudWatch Log Group |
| log_group_arn | ARN of the CloudWatch Log Group |
| sns_topic_arn | ARN of the SNS topic for alarms |

## Future Enhancements

Consider adding:
- Email subscriptions to SNS topic
- Additional alarms (network, disk, memory)
- CloudWatch dashboards
- Log metric filters
- Anomaly detection alarms

## Tags

All resources are tagged with:
- Name: Descriptive resource name
- Environment: Environment identifier
- Project: Project name (via default_tags)
- ManagedBy: Terraform (via default_tags)
