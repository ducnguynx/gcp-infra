resource "google_compute_disk" "state" {
  name = local.state_disk_name
  zone = var.zone
  type = "pd-balanced"
  size = var.state_disk_size_gb

  labels = local.common_labels

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.required]
}

