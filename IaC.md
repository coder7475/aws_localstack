# Infrastructure As Code (IaC)

- Method of Managing and provisioning infrastructure through machine-readable data definition
- Treats Infrastructure like application code with version control and testing
- Eliminate Manual Configuration through automated, repeatable process
- Use declarative configuration files to define desired infrastructure state

## **Why Use Infrastructure as Code?**

- **Consistency**: Eliminate "it works on my machine" by deploying identical infrastructure everywhere.
- **Speed**: Provision complex infrastructure in minutes instead of days or weeks.
- **Reliability**: Reduce human error through automated, tested configurations.
- **Scalability**: Easily replicate infrastructure patterns across environments.
- **Cost Control**: Track and optimize resource usage through code-defined limits.

## Core IaC Concepts

- **Resources**: Infrastructure components like servers, databases, networks
- **Providers**: Plugins that interface with specific platforms (AWS, Docker, etc.)
- **State**: Record of infrastructure managed by Terraform
- **Modules**: Reusable infrastructure components and patterns
- **Variables**: Parameterized values for flexible configurations

# **Day 6: Terraform Basics + First Hands-on Project**

## 🎯 **Goals**

- Understand what Terraform is and why it’s used (IaC).
- Install & configure Terraform.
- Learn workflow: **init → plan → apply → destroy**.
- Write your **first Terraform file**.
- Use it with **LocalStack** to provision AWS-like resources.

---

## 🔹 **Step 1: Understand Terraform Basics**

Terraform = Infrastructure as Code (IaC).

### Terraform Overview

- Open-source infrastructure provisioning tool developed by HashiCorp
- Uses HashiCorp Configuration Language (HCL) for human-readable configurations
- Supports 3000+ providers including AWS, Azure, GCP, Docker, and Kubernetes
- Maintains state tracking to understand and manage infrastructure changes
- Provides plan and apply workflow for safe infrastructure modifications
- Write infra in `.tf` files.
- Providers = plugins (e.g., AWS, Docker, Kubernetes).
- Core commands:
  - `terraform init` → download provider plugins.
  - `terraform plan` → preview changes.
  - `terraform apply` → make changes.
  - `terraform destroy` → remove resources.

---

## **Infrastructure as Code Lifecycle**: From Configuration to Running Resources

1. Write configuration files defining desired infrastructure state
2. Plan infrastructure changes using IaC plan command
3. Review proposed changes and validate configuration
4. Apply changes using terraform apply command
5. Manage ongoing infrastructure updates and maintenance through code

## 🔹 **Step 2: Install Terraform**

1. Download Terraform → [https://developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)

For Linux

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

2. Verify installation:

```bash
terraform -v
```

---

## 🔹 **Step 3: Setup LocalStack Provider**

We’ll use **Terraform + LocalStack** (instead of real AWS).

Create a file → `main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  endpoints {
    s3 = "http://localhost:4566"
  }
}
```

🔑 Explanation:

- `provider "aws"` → tells Terraform to use AWS provider.
- We override endpoint → LocalStack runs at `http://localhost:4566`.
- Fake credentials (`test/test`).

---

## 🔹 **Step 4: Create First Resource (S3 Bucket)**

Add this to `main.tf`:

```hcl
resource "aws_s3_bucket" "mybucket" {
  bucket = "day6-terraform-bucket"
}
```

Now you have **Terraform config** for a bucket.

---

## 🔹 **Step 5: Run Terraform Commands**

```bash
terraform init
```

- Downloads provider plugin.

```bash
terraform plan
```

- Shows what will be created.

```bash
terraform apply -auto-approve
```

- Actually creates bucket in LocalStack.

Verify with AWS CLI:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

✅ You should see `day6-terraform-bucket`.

---

## 🔹 **Step 6: Update Resource**

Change `main.tf`:

```hcl
resource "aws_s3_bucket" "mybucket" {
  bucket = "day6-terraform-bucket"
  tags = {
    Environment = "Dev"
    Owner       = "Day6"
  }
}
```

Re-run:

```bash
terraform plan
terraform apply -auto-approve
```

Now bucket has tags.

---

## 🔹 **Step 7: Destroy Resource**

Clean up:

```bash
terraform destroy -auto-approve
```

Verify:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

Bucket gone ✅

---

## **End of Day 6 – Outcome**

- Terraform workflow: **init → plan → apply → destroy**.
- How to configure Terraform with LocalStack.
- How to provision + update + destroy resources.
- Hands-on IaC with S3 bucket example.

## Practice labs

- [DevOpsXLabs](https://www.devopsxlabs.com/labs)
