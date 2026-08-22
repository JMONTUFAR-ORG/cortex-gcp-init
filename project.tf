# ---------------------------------------------------------------------------
# project.tf
# Creates the project that will host the service account, the Workload
# Identity Pool and the Pub/Sub resources managed by the main repository.
#
# Whoever runs this bootstrap needs, on top of Organization Admin:
#   - roles/resourcemanager.projectCreator on the organization or the folder
#   - roles/billing.user on the billing account (to attach it)
# ---------------------------------------------------------------------------

resource "google_project" "host" {
  project_id = var.project_id
  name       = var.project_name

  # Parent selection: folder when folder_id is provided, organization otherwise.
  # Only one of the two may be populated; the other must stay null.
  folder_id = var.folder_id
  org_id    = var.folder_id == null ? var.organization_id : null

  # Attaches the billing account. Required before Pub/Sub and other paid APIs
  # can be enabled.
  billing_account = var.billing_account

  labels = var.project_labels

  # Do not create the "default" VPC network and its permissive firewall rules.
  # This project hosts no network workloads.
  auto_create_network = false

  # Since google provider 6.0 the default value of deletion_policy is PREVENT,
  # which stops Terraform from deleting or recreating the project. Declared
  # explicitly so the intent is visible in code.
  deletion_policy = "PREVENT"
}

# configures Cloud Audit Logging for a specific Google Cloud project. 
# It allows you to manage ADMIN_READ, DATA_READ, and DATA_WRITE log types 
# for all services or an individual service
resource "google_project_iam_audit_config" "host_audit" {
  project = google_project.host.id
  service = "allServices"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
