# Hosting a Static Website on S3 with LocalStack (AWS CLI)

This guide demonstrates how to create an S3 bucket, configure it for static website hosting, and deploy files locally using [LocalStack](https://localstack.cloud/) with the **AWS CLI**.

## Step 1: Create a Bucket

Run the following command to create a bucket named `testwebsite`:

```bash
aws --endpoint-url=http://localhost:4566 s3 mb s3://testwebsite --profile localstack
```

**List Buckets**

```bash
aws s3 ls --endpoint-url=http://localhost:4566 --profile localstack
```

---

## Step 2: Add a Bucket Policy

Create a file named `bucket_policy.json` in the project root with the following contents:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::testwebsite/*"
    }
  ]
}
```

Attach the policy to the bucket:

```bash
aws s3api put-bucket-policy --bucket testwebsite --policy file://bucket_policy.json --endpoint-url=http://localhost:4566 --profile localstack
```

---

## Step 3: Upload Files

Sync your local project root to the S3 bucket:

```bash
aws s3 sync ./ s3://testwebsite --endpoint-url=http://localhost:4566 --profile localstack
```

---

## Step 4: Enable Static Website Hosting

Configure the S3 bucket for static website hosting:

```bash
aws s3 website s3://testwebsite/ --index-document index.html --error-document error.html --endpoint-url=http://localhost:4566 --profile localstack
```

---

## Step 5: Access the Website

In **LocalStack**, your static website endpoint follows this format:

```
http://<BUCKET_NAME>.s3-website.localhost.localstack.cloud:4566
```

For this example:

```
http://testwebsite.s3-website.localhost.localstack.cloud:4566/
```

`curl` the link:

````
curl http://testwebsite.s3-website.localhost.localstack.cloud:4566/
``
---

## Terraform Automation

You can also automate this setup with **Terraform**.

### Provider Configuration (`provider.tf`)

```hcl
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://s3.localhost.localstack.cloud:4566"
  }
}
````

### Variables (`variables.tf`)

```hcl
variable "bucket_name" {
  description = "Name of the s3 bucket. Must be unique."
  type        = string
}

variable "tags" {
  description = "Tags to set on the bucket."
  type        = map(string)
  default     = {}
}
```

### Outputs (`outputs.tf`)

```hcl
output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.s3_bucket.arn
}

output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.s3_bucket.id
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.s3_bucket.website_endpoint
}
```

### Main Configuration (`main.tf`)

```hcl
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_object" "html_files" {
  for_each     = fileset("${path.root}", "*.html")
  bucket       = var.bucket_name
  key          = basename(each.value)
  source       = each.value
  etag         = filemd5(each.value)
  content_type = "text/html"
  acl          = "public-read"
}
```

---

## Deployment with Terraform

```bash
terraform init
terraform plan
terraform apply
```

When prompted, enter a bucket name (e.g., `testbucket`).

You will see output with the ARN, bucket name, and website endpoint, such as:

```
website_endpoint = "testbucket.s3-website.localhost.localstack.cloud:4566"
```

Now visit the endpoint in your browser to see your static website.

---
