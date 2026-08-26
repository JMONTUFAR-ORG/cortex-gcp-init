# Cortex Cloud GCP Initial Setup

This terraform is meant to create necessary resources to perform the onboarding 
of Cortex Cloud

Run once, manually, to create everything the main repository needs in order to
authenticate without JSON keys:

- Host project for the automation (billing attached, no default network)
- API enablement on that project
- Service account `crtx-gcp-deployer` (keyless) holding Token Creator on itself
- Workload Identity Pool and GitHub OIDC provider, restricted to one repository
  and one branch (optional)
- Minimal custom role `tfOrgIamPolicyEditor` plus organization and project roles
- GCP Organization Policy to allow Cortex Service Principals be able to assume
  roles inside GCP Org (optional)
- State bucket and it's required permission for the Service Principal to store 
  the Terraform State files (optional)

> NOTE
>
> * The Workload Identity configuration, GCP Organization policy and State Bucket configuration can be controlled through the variables `create_wif`, `update_org_policy` and `create_state_bucket` variables respectively
> * For more details about the variables, check the variables.tf file


## Pre-requisites

### Permissions required to run this terraform

- `roles/resourcemanager.organizationAdmin` on the organization
- `roles/resourcemanager.projectCreator` on the organization or the target folder
- `roles/billing.user` on the billing account

### Environment
The environment where this terraform is going to be deployed must contain a terraform version higher than **1.5.0**

### GitHub Repository
It is recommended that you have already the repository with the Terraform Code downloaded from Cortex Cloud 
(excluding the tfvars file). If you are going to enable WIF, the repository name must match the variable 
`github_repository`


## Process

### Setup the variables
Create a new variables file by executing the following command:
```bash
cp terraform.tfvars.example terraform.tfvars
```
And edit them according to you requirements. Since this is going to create a project, be sure that the `project_id` variable is unique

If the variable `update_org_policy` is set to `true` (which is the default value) then its required to do the following:
1. Inside GCP at the Org level, go to IAM & Admin > Organization Policies and search for the policy named 
  `iam.allowedPolicyMemberDomains`
2. Take the list of Allowed values. This list should contain by default only the current Customer ID of the Workspace 
  related to the GCP Organization. If this policy is set to allow `All` extract the Customer ID from the Google Workspace
  by going to the [Google Workspace Admin Console](https://admin.google.com) > Account > Account Settings and get the value the **Customer ID**
3. Construct the variable `customer_ids` in the `terraform.tfvars` file. This should contain the least of allowed values
  in the GCP Policy, or only the Customer ID from the Google Workspace, plus the Customer ID from Cortex Cloud which is **C00v1avrt**. This variable should be left as the following example:
  ```yaml
  customer_ids = ["C00v2aaaa", "C00v1avrt"]
  ```

### Deploy the terraform

Inside the GCP Cloud Shell (on the latest version terraform must be installed separetely), or any authenticated environment with terraform, upload the terraform files and run the following commands:

```bash
terraform init
terraform fmt
terraform plan --var-file terraform.tfvars
terraform apply --var-file terraform.tfvars
```

> Notes
>
> * The project is created with `deletion_policy = "PREVENT"`. To destroy it you must first set the policy to `DELETE` and apply that change.
> * Changes to the pool, the provider or IAM policies can take up to 5 minutes to propagate.

If you need to re-read the output execute:
```bash
terraform output
```

### Google Workspace Admin Console

1. Login in to the Google Workspace Admin Console
2. If there's no super admin to re-use, then create a dedicated super admin, for example `tf-superadmin@yourdomain.com`,
   sign in once to accept the Terms of Service, and enforce 2SV on it.
3. Go to Security > API controls > Domain-wide delegation > Add new:
   - Client ID: the `service_account_unique_id` output
   - Scope: the `dwd_oauth_scope` output (that scope only)

## What to copy into the main repository

- `project_id` into the main repository's project variable
- `workload_identity_provider` and `service_account_email` into
  `google-github-actions/auth@v3`
- `service_account_email` into the `onboarding_service_account_email` variable for the
  `googleworkspace` provider

