Here’s an improved and more concise version of your CloudWatch guide. I’ve focused on clarity, flow, and readability while keeping all essential steps and commands:

---

# Amazon CloudWatch: Monitoring EC2 Logs and Metrics

## Objective

Learn how Amazon CloudWatch collects, stores, and visualizes logs and metrics for EC2 instances, and configure monitoring and log collection using Terraform, AWS CLI, or LocalStack.

---

## 1. Conceptual Overview

### 1.1 Metrics

- **Definition**: Numerical data points representing system performance (CPU, memory, network traffic).
- **Default EC2 Metrics**: CPUUtilization, DiskReadOps, DiskWriteOps, NetworkIn, NetworkOut.
- **Custom Metrics**: Applications can publish custom metrics for specialized monitoring.

### 1.2 Logs

- **Log Groups**: Containers to organize logs.
- **Log Streams**: Individual sequences of log events (usually per EC2 instance).
- **Agent Requirement**: CloudWatch Agent forwards system/application logs to CloudWatch.

### 1.3 Alarms

- **Functionality**: Monitor metrics and trigger actions when thresholds are breached.
- **Actions**: Send notifications via SNS or trigger automated responses like scaling.

---

## 2. Environment Preparation

- Terraform installed and configured.
- AWS CLI set up, or LocalStack for local testing.
- One running EC2 instance.

---

## 3. Enable EC2 Metrics Collection

EC2 automatically publishes basic metrics every 5 minutes. Enable detailed monitoring for 1-minute granularity.

```hcl
resource "aws_instance" "monitored_ec2" {
  ami                         = "ami-df5de72bdb3b"
  instance_type               = "t2.micro"
  monitoring                  = true
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = { Name = "MonitoredEC2" }
}
```

**Verify:** CloudWatch Console → Metrics → EC2 → Per-Instance Metrics.

---

## 4. Install and Configure CloudWatch Agent (Logs)

### Connect to EC2

```bash
ssh -i monitored-key root@<publicIP>
```

### Install Agent

```bash
wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo dpkg -i amazon-cloudwatch-agent.deb
```

### Configure Logs

`/opt/aws/amazon-cloudwatch-agent/bin/config.json`:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "EC2-SystemLogs",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

### Start Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
```

**Verify:** CloudWatch → Log Groups → EC2-SystemLogs.

---

## 5. Configure a CloudWatch Alarm

### Terraform Example

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "HighCPUAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = { InstanceId = aws_instance.monitored_ec2.id }
}
```

---

## 6. LocalStack Example (AWS CLI)

### Create Log Group

```bash
aws logs create-log-group --log-group-name EC2-SystemLogs \
  --endpoint-url=http://localhost:4566 --profile localstack
```

### Create Log Stream

```bash
aws logs create-log-stream --log-group-name EC2-SystemLogs --log-stream-name test-stream \
  --endpoint-url=http://localhost:4566 --profile localstack
```

### Push Logs

```bash
aws logs put-log-events --log-group-name EC2-SystemLogs --log-stream-name test-stream \
  --log-events timestamp=$(date +%s%3N),message="Hello LocalStack CloudWatch!" \
  --endpoint-url=http://localhost:4566 --profile localstack
```

### List Groups/Streams

```bash
aws logs describe-log-groups --endpoint-url=http://localhost:4566 --profile localstack
aws logs describe-log-streams --log-group-name EC2-SystemLogs --endpoint-url=http://localhost:4566 --profile localstack
aws logs get-log-events --log-group-name EC2-SystemLogs --log-stream-name test-stream --endpoint-url=http://localhost:4566 --profile localstack
```

---

## 7. Testing and Validation

### Stress Test

```bash
apt install -y stress
stress --cpu 2 --timeout 60
```

**Verify:**

- CPU metrics: CloudWatch → Metrics → EC2 → CPUUtilization
- Logs: CloudWatch → Log Groups → EC2-SystemLogs
- Alarm triggers if CPU > 80% for 2 consecutive periods.

**Comparison:**

- Metrics: Numerical performance indicators.
- Logs: Detailed event data for troubleshooting.

---

## Deliverables

- EC2 instance with detailed monitoring.
- CloudWatch Agent forwarding logs.
- CloudWatch Alarm monitoring CPU.

---

## References

- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [CloudWatch Agent Setup](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
