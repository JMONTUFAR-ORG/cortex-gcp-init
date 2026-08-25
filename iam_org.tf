# ---------------------------------------------------------------------------
# iam_org.tf
# ORGANIZATION level roles for the service account, limited to what
# google_organization_iam_*, google_organization_iam_custom_role and
# google_logging_organization_sink actually need.
# ---------------------------------------------------------------------------

# Minimal custom role to read and write the organization IAM policy.
# roles/resourcemanager.organizationAdmin carries far more; this one only
# carries the three permissions Terraform uses for
# google_organization_iam_member / google_organization_iam_binding.
resource "google_organization_iam_custom_role" "tf_org_iam_policy_editor" {
  org_id      = var.organization_id
  role_id     = "tfOrgIamPolicyEditor"
  title       = "TF Org IAM Policy Editor"
  description = "Lets Terraform read and write the organization IAM policy"
  permissions = [
    "resourcemanager.organizations.get",
    "resourcemanager.organizations.getIamPolicy",
    "resourcemanager.organizations.setIamPolicy",
  ]
}

locals {
  # Organization roles:
  # - custom role: organization IAM policy (organization_iam_member / binding)
  # - iam.organizationRoleAdmin: create and edit custom roles
  #   (organization_iam_custom_role)
  # - logging.configWriter: create sinks (logging_organization_sink)
  org_roles = [
    "roles/iam.organizationRoleAdmin",
    "roles/logging.configWriter",
  ]
}

# *_iam_member is used instead of *_iam_binding so existing members holding
# these roles on the organization are not wiped out.
resource "google_organization_iam_member" "tf_deployer" {
  for_each = toset(local.org_roles)

  org_id = var.organization_id
  role   = each.value
  member = "serviceAccount:${google_service_account.tf_deployer.email}"
}

resource "google_organization_iam_member" "tf_policy_editor" {
  org_id = var.organization_id
  role   = google_organization_iam_custom_role.tf_org_iam_policy_editor.id
  member = "serviceAccount:${google_service_account.tf_deployer.email}"
}

# Organization policy to restrict allowed domains for IAM members
resource "google_organization_policy" "domain_restriction" {
  count      = var.update_org_policy ? 1 : 0
  org_id     = var.organization_id
  constraint = "constraints/iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      values = var.customer_ids
    }
  }
}
