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
