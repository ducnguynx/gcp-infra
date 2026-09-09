resource "google_compute_address" "static_ipv4" {
  name         = "${var.name_prefix}-vps-ipv4"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "STANDARD"

  depends_on = [google_project_service.required]
}

resource "google_compute_instance" "vps" {
  name         = local.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  description         = "Reproducible homelab services host"
  deletion_protection = true

  tags   = [local.public_server_tag]
  labels = local.common_labels

  allow_stopping_for_update = true
  can_ip_forward            = false

  boot_disk {
    auto_delete = true
    device_name = "${local.vm_name}-boot"

    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = google_compute_disk.state.id
    device_name = local.state_disk_name
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.primary.id

    access_config {
      nat_ip       = google_compute_address.static_ipv4.address
      network_tier = "STANDARD"
    }
  }

  metadata = {
    block-project-ssh-keys = "TRUE"
    enable-oslogin         = "FALSE"
    serial-port-enable     = "FALSE"
    ssh-keys               = "${var.admin_username}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
    startup-script = templatefile("${path.module}/templates/bootstrap.sh.tftpl", {
      application_user            = var.application_user
      application_uid             = var.application_uid
      state_device_name           = local.state_disk_name
      state_mountpoint            = "/srv/state"
      repository_bootstrap_script = file("${path.module}/templates/scripts/repository-bootstrap")
      render_secrets_script       = file("${path.module}/templates/scripts/render-secrets")
      deploy_script               = file("${path.module}/templates/scripts/deploy")
      repository_unit = file(
        "${path.module}/templates/systemd/homelab-repository.service"
      )

      secrets_unit = file(
        "${path.module}/templates/systemd/homelab-secrets.service"
      )

      app_unit = file(
        "${path.module}/templates/systemd/homelab-app.service"
      )

      deploy_unit = file(
        "${path.module}/templates/systemd/homelab-deploy.service"
      )
    })
  }

  service_account {
    email  = google_service_account.runtime.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}
