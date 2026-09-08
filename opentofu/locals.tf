locals {
  vm_name           = "${var.name_prefix}-vps"
  state_disk_name   = "${var.name_prefix}-state"
  runtime_sa_id     = "${var.name_prefix}-vps-runtime"
  public_server_tag = "${var.name_prefix}-public-server"

  common_labels = {
    environment = "production"
    managed_by  = "opentofu"
    project     = "homelab"
  }

  required_apis = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
  ])
}

