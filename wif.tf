# ---------------------------------------------------------------------------
# wif.tf
# Workload Identity Federation: pool, GitHub OIDC provider and the
# impersonation grant. This is where "who may authenticate" is enforced.
# ---------------------------------------------------------------------------

# Pool: logical container for external identities. One pool per external
# environment is the recommended pattern (here, GitHub Actions).
resource "google_iam_workload_identity_pool" "github" {
  count                     = var.create_wif ? 1 : 0
  project                   = google_project.host.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "Federated identities coming from GitHub Actions"
  disabled                  = false

  depends_on = [google_project_service.required]
}

# OIDC provider: describes GitHub as the token issuer.
resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = var.create_wif ? 1 : 0
  project                            = google_project.host.project_id
  workload_identity_pool_id          = one(google_iam_workload_identity_pool.*.github.workload_identity_pool_id)
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  # attribute_mapping translates claims from the GitHub JWT into Google
  # attributes.
  # - google.subject is mandatory
  # - attribute.repository and attribute.ref are used by the condition below
  #   and by the impersonation binding
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  # attribute_condition (CEL): ONLY tokens from this repository AND this branch
  # can enter the pool. Forks, other branches and pull requests are denied at
  # the STS exchange.
  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.ref == '${var.github_ref}'"

  oidc {
    # Official GitHub Actions OIDC token issuer
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Impersonation grant: pool identities whose repository attribute matches the
# repo may act as the service account. The branch restriction is already
# enforced by the provider condition, so matching the repository is enough here.
resource "google_service_account_iam_member" "wif_user" {
  count              = var.create_wif ? 1 : 0
  service_account_id = google_service_account.tf_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${one(google_iam_workload_identity_pool.*.github.name)}/attribute.repository/${var.github_repository}"
}
