output "external_ipv4" {
  description = "Static public IPv4 address to use in DNS records."
  value       = google_compute_address.static_ipv4.address
}

output "ssh_target" {
  description = "OpenSSH target after the VM is created."
  value       = "${var.admin_username}@${google_compute_address.static_ipv4.address}"
}

output "state_disk_name" {
  description = "Protected persistent disk containing application state."
  value       = google_compute_disk.state.name
}

output "state_mountpoint" {
  description = "Mount point prepared by the startup bootstrap."
  value       = "/srv/state"
}

output "runtime_service_account" {
  description = "Dedicated VM service account; no project-wide role is granted in Phase 1."
  value       = google_service_account.runtime.email
}

