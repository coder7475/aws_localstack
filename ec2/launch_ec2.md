### Prerequisites for Emulating an EC2 Instance with LocalStack

To emulate an Amazon Elastic Compute Cloud (EC2) instance on a local machine using LocalStack, ensure the following requirements are met:

- A Linux host operating system is required, as network access to emulated instances is not supported on macOS.
- Docker Engine must be installed and running, as LocalStack uses Docker containers to emulate EC2 instances.
- LocalStack Pro edition (or equivalent, such as the Hobby Plan) is necessary for full EC2 emulation capabilities. The Community edition provides only basic mock operations.
- Obtain a LocalStack authentication token by signing up for the Pro or Hobby Plan via the LocalStack website.
- Install the AWS Command Line Interface (CLI) if not already present, using the official AWS installation guide.
- Install the LocalStack CLI via Python's package manager: `pip install localstack`.
- Basic familiarity with command-line tools and AWS CLI syntax is assumed.

Here’s your guide updated to use the **`aws` CLI** (instead of `awslocal`) with a **LocalStack profile**. I also added the necessary `--endpoint-url` and `--profile localstack` flags so the commands work with LocalStack:

### Step-by-Step Instructions to Run an EC2 Instance Locally

1. **Set Up the LocalStack Environment**

```bash
export LOCALSTACK_AUTH_TOKEN=your-auth-token-here
localstack start
curl http://localhost:4566/_localstack/info | jq
```

Confirm output shows `"edition": "pro"` and `"is_license_activated": true`.

---

2. **Create an EC2 Key Pair**

```bash
aws ec2 create-key-pair \
  --key-name my-key \
  --query 'KeyMaterial' \
  --output text \
  --endpoint-url=http://localhost:4566 \
  --profile localstack | tee key.pem

chmod 400 key.pem
```

Or import an existing public key:

```bash
aws ec2 import-key-pair \
  --key-name my-key \
  --public-key-material file://~/.ssh/id_rsa.pub \
  --endpoint-url=http://localhost:4566 \
  --profile localstack
```

---

3. **Get the Default Security Group**

```bash
sg_id=$(aws ec2 describe-security-groups \
  --endpoint-url=http://localhost:4566 \
  --profile localstack | jq -r '.SecurityGroups[0].GroupId')

echo "Security Group ID: $sg_id"
```

_Note: The default security group allows SSH access (port 22) by default in LocalStack._

---

4. **Launch the EC2 Instance**

AMI for ubuntu-22.04-jammy-jellyfish: ami-df5de72bdb3b

```bash
aws ec2 run-instances \
  --image-id ami-df5de72bdb3b \
  --count 1 \
  --instance-type t3.nano \
  --key-name my-key \
  --security-group-ids $sg_id \
  --endpoint-url=http://localhost:4566 \
  --profile localstack
```

_Note: Instance type has no functional impact in LocalStack. For Amazon Linux, use AMI `ami-024f768332f0`._

---

5. **Verify the Instance Status**

```bash
docker ps
instance_id=$(aws ec2 describe-instances \
  --endpoint-url=http://localhost:4566 \
  --profile localstack | jq -r '.Reservations[0].Instances[0].InstanceId')

aws ec2 describe-instances \
  --instance-ids $instance_id \
  --endpoint-url=http://localhost:4566 \
  --profile localstack | jq
```

---

6. **Get the Instance Public IP Address**

```bash
public_ip=$(aws ec2 describe-instances \
  --instance-ids $instance_id \
  --endpoint-url=http://localhost:4566 \
  --profile localstack | jq -r '.Reservations[0].Instances[0].PublicIpAddress')

echo "Public IP: $public_ip"
```

---

7. **Access the Instance via SSH**

```bash
ssh -i key.pem ubuntu@$public_ip
```

Or if you prefer to use the IP directly:

```bash
ssh -i key.pem ubuntu@<public-ip-address>
```

_Note: Replace `<public-ip-address>` with the actual IP address from the previous step._

---

8. **Terminate the Instance**

```bash
aws ec2 terminate-instances \
  --instance-ids $instance_id \
  --endpoint-url=http://localhost:4566 \
  --profile localstack
```
