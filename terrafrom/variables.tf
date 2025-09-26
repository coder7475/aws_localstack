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
