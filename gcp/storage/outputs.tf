output "bucket_names" {
  description = "Names of all created buckets, keyed by purpose"
  value       = { for k, b in google_storage_bucket.main : k => b.name }
}

output "bucket_urls" {
  description = "GCS URLs (gs://...) of all created buckets, keyed by purpose"
  value       = { for k, b in google_storage_bucket.main : k => b.url }
}

output "data_bucket_self_link" {
  description = "Self link of the data bucket specifically"
  value       = google_storage_bucket.main["data"].self_link
}