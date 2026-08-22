# ---------------------------------------------------------------------------
# iam_project.tf
# PROJECT level roles for the service account, scoped to the project created
# by this module.
# NOTE: roles/serviceusage.serviceUsageAdmin is deliberately NOT granted. The
# service account cannot enable or disable APIs; that stays with the bootstrap.
# ---------------------------------------------------------------------------

locals {
  # - pubsub.admin: topics, subscriptions and their IAM bindings
  #   (pubsub.editor does NOT include setIamPolicy, hence admin)
  # - iam.serviceAccountAdmin: create service accounts and manage their IAM
  #   policies (service_account_iam_member)
  project_roles = [
    "roles/pubsub.admin",
    "roles/iam.serviceAccountAdmin",
  ]
}

resource "google_project_iam_member" "tf_deployer" {
  for_each = toset(local.project_roles)

  project = google_project.host.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_deployer.email}"
}
