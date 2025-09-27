# 🔐 **Day 10–12 Combined: Networking & EC2 in Terraform**

### **Concepts Covered**

- **Internet Gateway (IGW):** A scalable, highly available VPC component that enables communication between instances in your VPC and the internet. It serves as a gateway for public subnets, allowing inbound and outbound traffic to the public internet while performing network address translation (NAT) for instances with public IP addresses.
- **NAT Gateway:** A managed service that provides outbound internet access for resources in private subnets without exposing them to inbound internet traffic. It requires an Elastic IP address and must be placed in a public subnet, ensuring secure, one-way connectivity for updates, patches, or external API calls.
- **Security Groups:** Act as virtual firewalls at the instance level. They are stateful, meaning that if an inbound rule allows traffic, the corresponding outbound response is automatically permitted. Rules can control ingress and egress based on protocols, ports, and source/destination IP ranges or other security groups.
- **Network ACLs (NACLs):** Operate as stateless firewalls at the subnet level. Unlike security groups, they evaluate rules in numbered order for both ingress and egress traffic, requiring explicit allowances for return traffic. They provide an additional layer of security for controlling traffic flow into and out of subnets.
- **EC2 Instances:** Virtual servers in AWS that can be launched within specific subnets of a VPC. When using Terraform, instances are defined declaratively, including attributes such as AMI, instance type, subnet placement, security groups, and IP assignment, enabling automated provisioning and management.

This combined module builds a foundational secure network architecture, emphasizing isolation between public and private resources while maintaining controlled access.

---

## **Prerequisites**

To follow this guide effectively, ensure you have:

- An AWS account with appropriate permissions (e.g., for VPC, EC2, and networking resources).
- Terraform installed (version 1.5 or later recommended for stability and features).
- AWS CLI configured with access keys or an IAM role.
- A basic understanding of AWS networking concepts and HCL (HashiCorp Configuration Language).
- An SSH key pair created in AWS for instance access (replace "your-key-pair" in code snippets with your key name).
- A valid AMI ID for your region (e.g., use the AWS Management Console or CLI to find the latest Amazon Linux 2 AMI; the placeholder "ami-12345678" should be updated accordingly).

Create a project directory, place the Terraform files (e.g., `main.tf`, `variables.tf`), and run `terraform init` to initialize the providers.

In a `variables.tf` file, define customizable inputs:

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "ami_id" {
  default = "ami-12345678"  # Replace with a valid AMI ID for your region
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "your-key-pair"  # Replace with your SSH key pair name
}
```

In `main.tf`, configure the AWS provider:

```hcl
provider "aws" {
  region = var.aws_region
}
```

---

## **Step 1: Setup VPC with Public & Private Subnets**

Start by creating a Virtual Private Cloud (VPC) to isolate your network environment. The VPC defines a logical boundary with a specified CIDR block, allowing for subnet segmentation.

- **Public Subnet:** Configured to automatically assign public IP addresses to instances, enabling direct internet access via the IGW.
- **Private Subnet:** Isolated from direct internet exposure, relying on the NAT Gateway for outbound connectivity.

This setup promotes security by default, adhering to the principle of least privilege.

👉 Terraform snippet (add to `main.tf`):

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "PrivateSubnet"
  }
}
```

Note: Enabling DNS support and hostnames facilitates name resolution within the VPC, which is essential for services like EC2 instance communication.

---

## **Step 2: Add Internet Gateway + NAT Gateway**

- **Internet Gateway (IGW):** Attaches to the VPC and provides a target for route tables, allowing bidirectional internet traffic for public resources. It is highly available and scales automatically.
- **NAT Gateway:** Requires an Elastic IP (EIP) for static public addressing. Placed in the public subnet, it translates private IP addresses to public ones for outbound traffic, preventing inbound connections and enhancing security.

This configuration ensures private resources can perform necessary outbound operations (e.g., software updates) without vulnerability to external threats.

👉 Terraform snippet (add to `main.tf`):

```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainIGW"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"  # Ensures compatibility with VPC
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]  # Ensures IGW is ready
  tags = {
    Name = "MainNATGateway"
  }
}
```

Best practice: Use `depends_on` to manage resource creation order, avoiding race conditions.

---

## **Step 3: Configure Route Tables**

Route tables direct network traffic within the VPC. Each subnet must be associated with a route table to define how traffic is routed.

- **Public Route Table:** Includes a default route (0.0.0.0/0) to the IGW for internet-bound traffic.
- **Private Route Table:** Includes a default route to the NAT Gateway, allowing outbound internet access while keeping the subnet private.

This separation enforces traffic isolation and security.

👉 Terraform snippet (add to `main.tf`):

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

---

## **Step 4: Security Groups & NACLs**

- **Security Groups:** Define granular rules for instances. The example allows SSH (port 22) from anywhere for demonstration; in production, restrict to specific IPs (e.g., your office CIDR). HTTP (port 80) is permitted for web traffic.
- **NACLs:** Provide subnet-wide rules. The default allows all traffic but can be customized (e.g., deny specific ports). Rules are evaluated in order, with lower numbers taking precedence; include explicit deny rules for security.

For the bastion pattern, create separate security groups: one for the public (bastion) instance allowing inbound SSH, and one for the private instance allowing SSH only from the bastion's security group.

👉 Terraform snippet (add to `main.tf`):

```hcl
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production, e.g., ["203.0.113.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "BastionSecurityGroup"
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]  # Allow SSH only from bastion
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For web traffic; restrict as needed
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PrivateSecurityGroup"
  }
}

resource "aws_network_acl" "main_nacl" {
  vpc_id = aws_vpc.main.id
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"  # Allow ephemeral ports for return traffic
    from_port  = 1024
    to_port    = 65535
  }
  tags = {
    Name = "MainNACL"
  }
}

resource "aws_network_acl_association" "public_nacl_assoc" {
  network_acl_id = aws_network_acl.main_nacl.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_network_acl_association" "private_nacl_assoc" {
  network_acl_id = aws_network_acl.main_nacl.id
  subnet_id      = aws_subnet.private.id
}
```

Note: NACLs are stateless, so include rules for return traffic (ephemeral ports). Always test rules to avoid locking yourself out.

---

## **Step 5: Launch EC2 in Public & Private Subnets**

- **Public EC2 (Bastion Host):** Placed in the public subnet with a public IP, serving as a secure jump host for accessing private resources.
- **Private EC2:** In the private subnet, with no public IP. It relies on the NAT Gateway for outbound internet access and can only be reached via the bastion.

Attach appropriate security groups and an SSH key pair for secure access.

👉 Terraform snippet (add to `main.tf`):

```hcl
resource "aws_instance" "public_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  tags = {
    Name = "PublicBastionEC2"
  }
}

resource "aws_instance" "private_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name
  tags = {
    Name = "PrivateEC2"
  }
}
```

To enable the bastion pattern, ensure the private instance's security group references the bastion's group ID.

---

## **Step 6: Verify**

1. Execute the Terraform workflow:

   ```bash
   terraform init
   terraform plan  # Review changes
   terraform apply -auto-approve
   ```

2. Obtain the public IP of the bastion EC2 from the AWS Console or Terraform output. SSH into it:

   ```bash
   ssh -i your-key.pem ec2-user@<public-ip>
   ```

3. From the bastion, SSH into the private EC2 (use its private IP, obtainable from the AWS Console):

   ```bash
   ssh ec2-user@<private-ip>
   ```

   This demonstrates the bastion pattern for secure access.

4. Test NAT functionality: From the private EC2, run `curl ifconfig.me` to confirm outbound internet access via the NAT Gateway's public IP.

5. Monitor logs and metrics in the AWS Console to verify traffic routing and security rules.

If issues arise, check VPC flow logs (enable via Terraform if needed) for debugging.

---

## **Optional Experiments**

- **Block Outbound Traffic in NACL:** Add a deny rule (e.g., rule_no 50, action "deny" for cidr_block "0.0.0.0/0") to the egress section and apply `terraform apply`. Test connectivity from instances to observe isolation.
- **Remove NAT Gateway Route:** Delete the private route to the NAT Gateway and reapply. Attempt outbound requests from the private EC2 to confirm loss of internet access.
- **Restrict SSH in Security Group:** Update the bastion_sg ingress to allow SSH only from your specific IP (e.g., cidr_blocks = ["your.ip.address/32"]). Reapply and test access restrictions.
- **Add Multi-AZ Resilience:** Extend subnets and NAT Gateways across multiple availability zones for high availability.
- **Integrate Monitoring:** Enable detailed monitoring on EC2 instances by adding `monitoring = true` to the resource blocks, and create CloudWatch alarms for metrics like CPU utilization.

This architecture provides a robust, secure foundation. For production, incorporate additional elements such as IAM roles for EC2 (e.g., for S3 access) and encryption at rest/transit. Refer to AWS documentation for region-specific details and Terraform best practices for modularization.
