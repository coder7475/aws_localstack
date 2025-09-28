# **CloudWatch Basics – Monitor EC2 Logs & Metrics**

## Goal for the Day

Understand how **Amazon CloudWatch** collects, stores, and visualizes **logs and metrics** for EC2 instances, and practice sending logs + monitoring metrics.

---

## **Step 1: Theoretical Foundation**

1. **CloudWatch Metrics**

   - Numerical data points (CPU utilization, memory, network traffic).
   - Default EC2 metrics: CPUUtilization, DiskReadOps, DiskWriteOps, NetworkIn, NetworkOut.
   - Custom metrics can be pushed from applications.

2. **CloudWatch Logs**

   - Log groups (containers for logs).
   - Log streams (individual streams, usually one per instance).
   - Agent required to push OS/application logs to CloudWatch.

3. **CloudWatch Alarms**

   - Triggered when a metric breaches a threshold.
   - Can send notifications via **SNS** or trigger an action.

---

## **Step 2: Environment Setup**

- Terraform installed.
- AWS CLI configured (or **LocalStack** for practice – but logs are limited there).
- One running EC2 instance (from Day 11/12 setup).

---

## **Step 3: Enable EC2 Metrics**

EC2 instances publish **basic metrics** automatically to CloudWatch every 5 minutes.
To enable **detailed monitoring** (1-minute intervals):

```hcl
resource "aws_instance" "monitored_ec2" {
  ami                         = "ami-12345678"
  instance_type               = "t2.micro"
  monitoring                  = true   # Enables detailed monitoring
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "MonitoredEC2"
  }
}
```

👉 After deployment, go to **CloudWatch Console → Metrics → EC2 → Per-Instance Metrics** to view CPUUtilization, NetworkIn, etc.

---

## **Step 4: Install & Configure CloudWatch Agent (for Logs)**

SSH into the EC2 instance and install the CloudWatch agent:

```bash
sudo yum install -y amazon-cloudwatch-agent
```

Create a config file `/opt/aws/amazon-cloudwatch-agent/bin/config.json`:

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

Start the agent:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
```

👉 Logs should now appear in CloudWatch **Log Groups**.

---

## **Step 5: Create a CloudWatch Alarm**

Terraform example for CPU utilization alarm:

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
  alarm_description   = "This metric monitors EC2 CPU usage"
  dimensions = {
    InstanceId = aws_instance.monitored_ec2.id
  }
}
```

---

## **Step 6: Validation**

- Stress test CPU on EC2:

```bash
sudo yum install -y stress
stress --cpu 2 --timeout 60
```

- Watch CloudWatch → Metrics → CPUUtilization.
- Verify logs under **Log Groups → EC2-SystemLogs**.

---

- Compare CloudWatch Logs vs Metrics.

---

✅ **End of Day 13 Deliverables**

- One EC2 instance with detailed monitoring enabled.
- CloudWatch Agent configured to push system logs.
- A CloudWatch Alarm set up to monitor CPU usage.

### References
