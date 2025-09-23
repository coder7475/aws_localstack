resource "aws_s3_bucket" "mybucket" {
  bucket = "day6-terraform-bucket"
  tags = {
    Environment = "Dev"
    Owner = "Day6"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyTerraformVPC"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "MyTerraformSubnet"
  }
}
