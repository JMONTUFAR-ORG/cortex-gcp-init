# WIF bootstrap for GitHub Actions + Terraform (GCP and Google Workspace)

Run once, manually, to create everything the main repository needs in order to
authenticate without JSON keys:

- Host project for the automation (billing attached, no default network)
- API enablement on that project
- Service account `crtx-gcp-deployer` (keyless) holding Token Creator on itself
- Workload Identity Pool and GitHub OIDC provider, restricted to one repository
  and one branch
- Minimal custom role `tfOrgIamPolicyEditor` plus organization and project roles

## Permissions required to run the bootstrap

- `roles/resourcemanager.organizationAdmin` on the organization
- `roles/resourcemanager.projectCreator` on the organization or the target folder
- `roles/billing.user` on the billing account

## Deliberately out of scope

- No state bucket is created. The main repository's backend must point at an
  existing bucket, and that bucket must separately grant the service account a
  role such as `roles/storage.objectUser`, scoped to the bucket only.
- The service account does NOT receive `roles/serviceusage.serviceUsageAdmin`,
  so it cannot enable APIs. Any new API is added to `local.required_apis` in
  `apis.tf` and applied from this bootstrap.

## How to run

```bash
gcloud auth application-default login
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your values
terraform init
terraform fmt
terraform plan --var-file terraform.tfvars
terraform apply --var-file
terraform output
```

## Remaining manual step (Google Workspace Admin Console)

1. Create a dedicated or re-use super admin, for example `tf-superadmin@yourdomain.com`,
   sign in once to accept the Terms of Service, and enforce 2SV on it.
2. Security > API controls > Domain-wide delegation > Add new:
   - Client ID: the `service_account_unique_id` output
   - Scope: the `dwd_oauth_scope` output (that scope only)

## What to copy into the main repository

- `project_id` into the main repository's project variable
- `workload_identity_provider` and `service_account_email` into
  `google-github-actions/auth@v3`
- `service_account_email` into the `service_account` argument of the
  `googleworkspace` provider

## Notes

- The project is created with `deletion_policy = "PREVENT"`. To destroy it you
  must first set the policy to `DELETE` and apply that change.
- Changes to the pool, the provider or IAM policies can take up to 5 minutes to
  propagate.
- If the main repository still declares `google_project_service` resources, the
  apply will fail with PERMISSION_DENIED on `serviceusage.services.enable`.
  Remove those resources and manage APIs here instead.
