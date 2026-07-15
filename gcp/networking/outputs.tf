output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "vpc_self_link" {
  description = "Self link of the VPC network (used when referencing this VPC from other resources)"
  value       = google_compute_network.main.self_link
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = google_compute_subnetwork.database.id
}

output "router_id" {
  description = "ID of the Cloud Router"
  value       = google_compute_router.main.id
}