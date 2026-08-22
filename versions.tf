# ---------------------------------------------------------------------------
# versions.tf
# Pins the Terraform and google provider versions.
# This bootstrap module is meant to be run ONCE, manually, by a human that
# holds Organization Admin, Project Creator and Billing User.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Local backend by default. If you already have a state bucket created some
  # other way, uncomment and point at it; this module does not create buckets.
  # backend "gcs" {
  #   bucket = "EXISTING_TFSTATE_BUCKET"
  #   prefix = "bootstrap-wif"
  # }
}

# The google provider uses the Application Default Credentials of whoever runs
# the bootstrap. No credentials are configured in code.
# "project" is intentionally NOT set here: the project does not exist yet when
# the apply starts. Every resource sets its own project from google_project.host.
provider "google" {
  region = var.region
}
