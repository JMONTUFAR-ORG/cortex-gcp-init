# ---------------------------------------------------------------------------
# service_account.tf
# Creates the service account GitHub Actions will impersonate. No JSON key is
# ever generated.
# ---------------------------------------------------------------------------

resource "google_service_account" "tf_deployer" {
  project      = google_project.host.project_id
  account_id   = var.service_account_id
  display_name = "Terraform org deployer (GitHub Actions via WIF)"
  description  = "Impersonated by GitHub Actions to deploy the organization baseline and Workspace roles"

  # The IAM API must be enabled before the service account can be created
  depends_on = [google_project_service.required]
}

# The service account grants Service Account Token Creator ON ITSELF.
# This is what lets the googleworkspace provider call iamcredentials.signJwt
# and sign a JWT with sub=super admin (domain-wide delegation without a key).
resource "google_service_account_iam_member" "self_token_creator" {
  service_account_id = google_service_account.tf_deployer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.tf_deployer.email}"
}
