# ---------------------------------------------------------------------------
# outputs.tf
# Values to copy into the GitHub workflow, the googleworkspace provider and the
# Workspace Admin Console.
# ---------------------------------------------------------------------------

output "project_id" {
  description = "ID of the project created by the bootstrap"
  value       = google_project.host.project_id
}

output "project_number" {
  description = "Project number, useful when building resource paths by hand"
  value       = google_project.host.number
}

output "workload_identity_provider" {
  description = "Value for workload_identity_provider in google-github-actions/auth@v3"
  # .name returns the full resource name:
  # projects/NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER
  value = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Value for service_account in auth@v3 and in the googleworkspace provider"
  value       = google_service_account.tf_deployer.email
}

output "service_account_unique_id" {
  description = "Client ID to register under Admin Console > Security > API controls > Domain-wide delegation"
  value       = google_service_account.tf_deployer.unique_id
}

output "dwd_oauth_scope" {
  description = "The only OAuth scope to authorize for domain-wide delegation"
  value       = "https://www.googleapis.com/auth/admin.directory.rolemanagement"
}

output "enabled_apis" {
  description = "APIs enabled by the bootstrap. The deployer service account cannot change this list."
  value       = sort(keys(google_project_service.required))
}
