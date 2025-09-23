output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "public_route_table_id" {
  value = aws_route.public_default_route.id
}

output "IGW_id" {
  value = aws_internet_gateway.IGW.id
}
