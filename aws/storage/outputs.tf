output "bucket_names" {
  description = "Names of all created buckets, keyed by purpose"
  value       = { for k, b in aws_s3_bucket.main : k => b.id }
}

output "bucket_arns" {
  description = "ARNs of all created buckets, keyed by purpose"
  value       = { for k, b in aws_s3_bucket.main : k => b.arn }
}

output "data_bucket_domain_name" {
  description = "Regional domain name of the data bucket specifically"
  value       = aws_s3_bucket.main["data"].bucket_regional_domain_name
}
