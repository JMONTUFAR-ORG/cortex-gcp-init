# ---------------------------------------------------------------------------
# variables.tf
# Module inputs. All values are supplied through terraform.tfvars.
# ---------------------------------------------------------------------------

variable "organization_id" {
  description = "Numeric GCP organization ID (for example: 123456789012)."
  type        = string
}

variable "folder_id" {
  description = <<-EOT
    Numeric ID of the folder that will contain the project (without the
    folders/ prefix). Leave null to create the project directly under the
    organization.
  EOT
  type        = string
  default     = null
}

variable "project_id" {
  description = <<-EOT
    ID of the project to CREATE. Must be globally unique, 6 to 30 characters,
    lowercase letters, digits and hyphens, starting with a letter.
  EOT
  type        = string

  # Local validation so a bad value fails at plan time instead of at the API
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Invalid project_id: use 6-30 characters, lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "project_name" {
  description = "Display name of the project in the console."
  type        = string
  default     = "Terraform Org Baseline"
}

variable "billing_account" {
  description = <<-EOT
    Billing account ID to attach to the project, in the format
    XXXXXX-XXXXXX-XXXXXX. Without billing, APIs such as Pub/Sub cannot be
    enabled.
  EOT
  type        = string
}

variable "project_labels" {
  description = "Labels applied to the project."
  type        = map(string)
  default = {
    managed-by = "terraform"
    purpose    = "org-baseline-automation"
  }
}

variable "region" {
  description = "Default region for the google provider."
  type        = string
  default     = "us-central1"
}

variable "github_repository" {
  description = "Authorized GitHub repository, in ORG/REPO format (for example: techworksgt/gcp-org-baseline)."
  type        = string
}

variable "github_ref" {
  description = "Branch allowed to impersonate the service account. Only this ref passes the attribute condition."
  type        = string
  default     = "refs/heads/main"
}

variable "service_account_id" {
  description = "ID of the service account Terraform will use from GitHub Actions."
  type        = string
  default     = "tf-org-deployer"
}

variable "pool_id" {
  description = "Workload Identity Pool ID."
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "Workload Identity Pool Provider ID (GitHub OIDC)."
  type        = string
  default     = "github-provider"
}

variable "customer_ids" {
  description = "The Customer IDs to authorize Cortex and existing Workspaces"
  type        = list(string)
  sensitive   = true
}

variable "create_state_bucket" {
  description = "Create a GCS bucket for Terraform state storage"
  type        = bool
  default     = false
}

variable "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state storage"
  type        = string
  default     = ""
}

variable "state_bucket_location" {
  description = "Location of the GCS bucket for Terraform state storage"
  type        = string
  default     = "US"
}