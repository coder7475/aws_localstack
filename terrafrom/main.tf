// S3
resource "aws_s3_bucket" "mybucket" {
  bucket = "day6-terraform-bucket"
  tags = {
    Environment = "Dev"
    Owner = "Day6"
  }
}

// IAM
resource "aws_iam_user" "dev" {
  name = "dev-user"
}

resource "aws_iam_group" "dev_group" {
  name = "dev-group"
}

resource "aws_iam_group_membership" "team" {
  name = "dev-team"
  users = [aws_iam_user.dev.name]
  group = aws_iam_group.dev_group.name
}

// Attack a predefined policy
resource "aws_iam_group_policy_attachment" "s3_full" {
  group      = aws_iam_group.dev_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

// create a policy
resource "aws_iam_policy" "s3_readonly" {
  name        = "S3ReadOnly"
  description = "Read-only access to S3"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:Get*", "s3:List*"]
        Resource = "*"
      }
    ]
  })
}

// create a role
resource "aws_iam_role" "s3_readonly_role" {
  name               = "s3-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

// attack the policy
resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  role       = aws_iam_role.s3_readonly_role.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}

// VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

// Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

// Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.private_subnet_cidr
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.vpc_name}-private-subnet"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.my_vpc.id
  tags = { Name = "${var.vpc_name}-igw"}
}

// Public Route Table 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = { Name = "${var.vpc_name}-public-route-table"}
}

// Add default route to internet through IGW
resource "aws_route" "public_default_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = var.public_route
  gateway_id = aws_internet_gateway.IGW.id
}

// Associate public route table to subnet
resource "aws_route_table_association" "public_route_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

// NAT Gateway with Elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"  
  tags = {
    Name = "NAT EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.IGW]  
  tags = {
    Name = "Main NAT Gateway"
  }
}

// Route Table for Private Subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.vpc_name}-private-route-table"
  }
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = var.public_route
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

// Security Groups & NACLs
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.my_vpc.id
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
  vpc_id = aws_vpc.my_vpc.id
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

# resource "aws_network_acl" "main_nacl" {
#   vpc_id = aws_vpc.my_vpc.id
#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 110
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }
#   ingress {
#     protocol   = "-1"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"  # Allow ephemeral ports for return traffic
#     from_port  = 1024
#     to_port    = 65535
#   }
#   tags = {
#     Name = "MainNACL"
#   }
# }

# resource "aws_network_acl_association" "public_nacl_assoc" {
#   network_acl_id = aws_network_acl.main_nacl.id
#   subnet_id      = aws_subnet.public_subnet.id
# }

# resource "aws_network_acl_association" "private_nacl_assoc" {
#   network_acl_id = aws_network_acl.main_nacl.id
#   subnet_id      = aws_subnet.private_subnet.id
# }

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow inbound SSH (⚠ restrict to admin IPs in real prod)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Allow inbound HTTP
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound HTTPS
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral return traffic
  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "PublicNACL"
  }
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow inbound SSH only from within the VPC (e.g., bastion)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.my_vpc.cidr_block
    from_port  = 22
    to_port    = 22
  }

  # Allow inbound HTTP (if private servers are behind an ALB)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = aws_vpc.my_vpc.cidr_block
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound DB traffic (example: MySQL on 3306) only within VPC
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = aws_vpc.my_vpc.cidr_block
    from_port  = 3306
    to_port    = 3306
  }

  # Allow ephemeral return traffic
  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = aws_vpc.my_vpc.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "PrivateNACL"
  }
}

# Associate Public NACL
resource "aws_network_acl_association" "public_assoc" {
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = aws_subnet.public_subnet.id
}

# Associate Private NACL
resource "aws_network_acl_association" "private_assoc" {
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = aws_subnet.private_subnet.id
}

// EC2
resource "aws_instance" "public_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
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
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name
  tags = {
    Name = "PrivateEC2"
  }
}