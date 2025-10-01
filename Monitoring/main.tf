
# Create a VPC for the monitored EC2 instance
resource "aws_vpc" "monitored_vpc" {
  cidr_block = "10.20.0.0/16"
  tags = {
    Name = "MonitoredVPC"
  }
}

# Create a public subnet in the VPC
resource "aws_subnet" "monitored_public_subnet" {
  vpc_id                  = aws_vpc.monitored_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "MonitoredPublicSubnet"
  }
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "monitored_igw" {
  vpc_id = aws_vpc.monitored_vpc.id
  tags = {
    Name = "MonitoredIGW"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "monitored_public_rt" {
  vpc_id = aws_vpc.monitored_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitored_igw.id
  }
  tags = {
    Name = "MonitoredPublicRouteTable"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "monitored_public_assoc" {
  subnet_id      = aws_subnet.monitored_public_subnet.id
  route_table_id = aws_route_table.monitored_public_rt.id
}

# Create a security group allowing SSH and ICMP (ping)
resource "aws_security_group" "monitored_sg" {
  name        = "monitored-ec2-sg"
  description = "Allow SSH and ICMP"
  vpc_id      = aws_vpc.monitored_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MonitoredEC2SG"
  }
}

# Create a key pair for SSH access
resource "aws_key_pair" "monitored_key" {
  key_name   = "monitored-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDh2gJhVt0iG2zyQZ7us3NDo0VEHBl6oHW4MPbcf4x3ifYlu9eT4HFi/zePRCzN62TP05xHG4ZmnQJF6/2u/MIU6sW18kQYJ7Qg4FEyKeg8W3YntocKTG7o9EZzhTqnmIA5bzm1ezeEz9Msu3iAbZK1k0r4TWOU7nzvevuhXY3aZ76AtI/gFKyp5cbcqT9bcWRjggrdkgohAcZu7S5UrxYgA3oVUVhGpQWk16TPi1SjmdUsdgX0Dv+2dNGWas2R2fCZKaLI5u2TJWWAHWxCHaEXampWCjf2jVqDZfNf3pTqSC1y1QOt4InmC+1enWIrFAesKn8eISvXz7tCCQlPgLaD fahad@OnePlace"
}

resource "aws_instance" "monitored_ec2" {
  ami                         = "ami-df5de72bdb3b" # AMI for ubuntu-22.04-jammy-jellyfish
  instance_type               = "t2.micro"
  monitoring                  = false
  subnet_id                   = aws_subnet.monitored_public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.monitored_sg.id]
  key_name                    = aws_key_pair.monitored_key.key_name

  tags = {
    Name = "MonitoredEC2"
  }
}

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
