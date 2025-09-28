# aws_localstack

## What is LocalStack?

LocalStack is a tool that emulates many AWS services **locally** on your machine. It’s great for learning and testing things like S3, DynamoDB, Lambda, API Gateway, etc. without connecting to the real AWS cloud.

---

## 🛠️ Setup Steps

### 1. Install Prerequisites

- **Docker** (required, since LocalStack runs as containers)
- **Python 3.8+** (optional, for `localstack-cli`)
- **AWS CLI** (to interact with services like in real AWS)

Check versions:

```bash
docker --version
python3 --version
aws --version
```

---

### 2. Install LocalStack

#### Option A: Using `pip` (recommended)

```bash
pip install localstack
```

#### Option B: Using Docker directly

```bash
docker run --rm -it -p 4566:4566 -p 4571:4571 localstack/localstack
```

---

### 3. Start LocalStack

If installed via `pip`:

```bash
localstack start -d
```

Check logs:

```bash
localstack logs
```

By default, services run on port **4566**.

Check info:

```bash
curl http://localhost:4566/_localstack/info | jq
```

---

### 4. Configure AWS CLI for LocalStack

Create a profile for LocalStack:

```bash
aws configure --profile localstack
```

Use dummy values:

- AWS Access Key ID: `test`
- AWS Secret Access Key: `test`
- Default region: `us-east-1`

Now tell AWS CLI to use LocalStack’s endpoint. Example with S3:

```bash
aws --endpoint-url=http://localhost:4566 s3 mb s3://my-bucket --profile localstack
```

List buckets:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls --profile localstack
```

---

### 5. Explore Services

Some commonly supported LocalStack services for learning:

- **S3** (storage)
- **DynamoDB** (NoSQL DB)
- **Lambda** (functions)
- **API Gateway** (APIs)
- **SNS & SQS** (messaging)
- **CloudFormation** (infrastructure as code)

Example DynamoDB:

```bash
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name Users \
    --attribute-definitions AttributeName=UserId,AttributeType=S \
    --key-schema AttributeName=UserId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --profile localstack
```

---

### 6. Automate with `docker-compose` (Recommended for real learning)

`docker-compose.yml`:

```yaml
version: "3.8"
services:
  localstack:
    image: localstack/localstack
    container_name: localstack_main
    ports:
      - "4566:4566"
      - "4571:4571"
    environment:
      - SERVICES=s3,dynamodb,lambda,apigateway,sqs,sns
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "./localstack:/var/lib/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
```

Start it:

```bash
docker-compose up -d
```
