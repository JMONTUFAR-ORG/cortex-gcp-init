# ---------------------------------------------------------------------------
# apis.tf
# Enables the required APIs on the project FROM THE BOOTSTRAP.
# This is deliberate: the deployer service account has no permission to enable
# APIs, so every API the main repository needs must be added here.
# ---------------------------------------------------------------------------

locals {
  # - iam / iamcredentials / sts: foundation of Workload Identity Federation
  #   and service account impersonation
  # - cloudresourcemanager: read and modify the org and project IAM policies
  # - pubsub / logging: resources deployed by the main repository
  # - admin: Admin SDK, required by the googleworkspace provider
  # - serviceusage: used by THIS BOOTSTRAP to enable the other APIs; it is not
  #   granted to the deployer service account
  required_apis = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "pubsub.googleapis.com",
    "logging.googleapis.com",
    "admin.googleapis.com",
  ]
}

# One resource per API using for_each.
# project is taken from the google_project resource rather than the variable so
# Terraform orders creation correctly: project first, then APIs.
resource "google_project_service" "required" {
  for_each = toset(local.required_apis)

  project = google_project.host.project_id
  service = each.value

  # Do not turn APIs off if this module is ever destroyed; other resources may
  # still depend on them.
  disable_on_destroy = false
}
