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

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC Gateway Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
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

output "flow_log_group_name" {
  description = "Name of the CloudWatch log group for VPC flow logs (null if disabled)"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}