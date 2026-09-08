resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = local.runtime_sa_id
  display_name = "Homelab VPS runtime identity"
  description  = "Least-privilege identity used by the homelab VPS. Roles are granted explicitly in later phases."

  depends_on = [google_project_service.required]
}

