output "instance_template_id" {
  description = "ID of the instance template"
  value       = google_compute_instance_template.main.id
}

output "instance_group_manager_id" {
  description = "ID of the managed instance group"
  value       = google_compute_region_instance_group_manager.main.id
}

output "instance_group_manager_instance_group" {
  description = "URL of the underlying instance group (useful for attaching a load balancer)"
  value       = google_compute_region_instance_group_manager.main.instance_group
}

output "health_check_id" {
  description = "ID of the health check"
  value       = google_compute_health_check.main.id
}

output "autoscaler_id" {
  description = "ID of the autoscaler (null if autoscaling is disabled)"
  value       = var.enable_autoscaling ? google_compute_region_autoscaler.main[0].id : null
}