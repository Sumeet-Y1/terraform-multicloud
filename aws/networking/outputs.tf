output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, keyed by AZ suffix"
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, keyed by AZ suffix"
  value       = { for k, s in aws_subnet.private : k => s.id }
}

output "database_subnet_ids" {
  description = "IDs of the database subnets, keyed by AZ suffix"
  value       = { for k, s in aws_subnet.database : k => s.id }
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways, keyed by AZ suffix"
  value       = { for k, n in aws_nat_gateway.main : k => n.id }
}

output "web_sg_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web.id
}

output "app_sg_id" {
  description = "ID of the app tier security group"
  value       = aws_security_group.app.id
}

output "database_sg_id" {
  description = "ID of the database tier security group"
  value       = aws_security_group.database.id
}