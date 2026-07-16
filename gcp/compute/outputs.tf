output "instance_ids" {
  description = "IDs of the created instances"
  value       = google_compute_instance.main[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of the created instances"
  value       = google_compute_instance.main[*].network_interface[0].network_ip
}

output "instance_names" {
  description = "Names of the created instances"
  value       = google_compute_instance.main[*].name
}