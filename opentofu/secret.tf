locals {
  application_secrets = {
    "github-deploy-key" = {
      service        = "deployment"
      payload_format = "openssh"
    }

    "grafana-admin-password" = {
      service        = "grafana"
      payload_format = "text"
    }

    "spotify-oauth" = {
      service        = "spotify"
      payload_format = "json"
    }

    "youtube-oauth" = {
      service        = "youtube"
      payload_format = "json"
    }
  }
}

resource "google_secret_manager_secret" "application" {
  for_each = local.application_secrets

  project   = var.project_id
  secret_id = each.key

  labels = merge(local.common_labels, {
    service        = each.value.service
    payload_format = each.value.payload_format
  })

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.required["secretmanager.googleapis.com"]
  ]
}

resource "google_secret_manager_secret_iam_member" "runtime_accessor" {
  for_each = google_secret_manager_secret.application

  project   = each.value.project
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}
