terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 8.1.0"
    }
  }

  backend "local" {
    path = "state/terraform.tfstate"
  }
}

