output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = aws_instance.main[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of the created EC2 instances"
  value       = aws_instance.main[*].private_ip
}

output "ami_used" {
  description = "AMI ID actually used for the instances"
  value       = local.ami_id
}