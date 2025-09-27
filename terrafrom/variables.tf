variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}


variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "vpc_name" {
  type    = string
  default = "my-vpc"
}

variable "avail_zone" {
  type    = string
  default = "us-east-1a"
}

variable "public_route" {
  type = string
  default = "0.0.0.0/0"
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