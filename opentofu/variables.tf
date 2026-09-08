variable "project_id" {
  description = "Existing GCP project ID with billing enabled."
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id must not be empty."
  }
}

variable "region" {
  description = "GCP region for regional resources."
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP zone for the VM and zonal state disk."
  type        = string
  default     = "asia-southeast1-b"

  validation {
    condition     = startswith(var.zone, "${var.region}-")
    error_message = "zone must belong to region."
  }
}

variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "homelab"

  validation {
    condition = (
      length(var.name_prefix) >= 2 &&
      length(var.name_prefix) <= 16 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix))
    )
    error_message = "name_prefix must be 2-16 lowercase letters, digits, or hyphens; it must start with a letter and end with a letter or digit."
  }
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "boot_image" {
  description = "GCP image family or exact image used for the disposable boot disk."
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "boot_disk_size_gb" {
  description = "Size of the disposable boot disk in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.boot_disk_size_gb >= 10 && floor(var.boot_disk_size_gb) == var.boot_disk_size_gb
    error_message = "boot_disk_size_gb must be a whole number of at least 10."
  }
}

variable "state_disk_size_gb" {
  description = "Initial size of the protected application-state disk in GiB."
  type        = number
  default     = 30

  validation {
    condition     = var.state_disk_size_gb >= 10 && floor(var.state_disk_size_gb) == var.state_disk_size_gb
    error_message = "state_disk_size_gb must be a whole number of at least 10."
  }
}

variable "subnet_cidr" {
  description = "IPv4 range for the custom subnet."
  type        = string
  default     = "10.20.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "admin_username" {
  description = "Linux username associated with the instance-level SSH public key."
  type        = string
  default     = "duc"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,30}$", var.admin_username))
    error_message = "admin_username is not a valid Linux username."
  }
}

variable "ssh_public_key_path" {
  description = "Local path to the administrator SSH public key. The private key is never read."
  type        = string
  default     = "~/.ssh/gcp-homelab_ed25519.pub"
}

variable "ssh_source_ranges" {
  description = "IPv4 CIDRs allowed to reach TCP/22. Prefer a trusted /32 when possible."
  type        = list(string)

  validation {
    condition = (
      length(var.ssh_source_ranges) > 0 &&
      alltrue([for cidr in var.ssh_source_ranges : can(cidrnetmask(cidr))])
    )
    error_message = "ssh_source_ranges must contain at least one valid IPv4 CIDR."
  }
}

variable "application_user" {
  description = "Dedicated local user that will own the future rootless Podman deployment."
  type        = string
  default     = "vps-app"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,30}$", var.application_user))
    error_message = "application_user is not a valid Linux username."
  }
}

variable "application_uid" {
  description = "Stable UID/GID for restored rootless Podman and bind-mount ownership."
  type        = number
  default     = 2000

  validation {
    condition = (
      var.application_uid >= 1000 &&
      var.application_uid <= 60000 &&
      floor(var.application_uid) == var.application_uid
    )
    error_message = "application_uid must be a whole number between 1000 and 60000."
  }
}
