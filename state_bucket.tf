# ---------------------------------------------------------------------------
# state_bucket.tf
# Optional GCS bucket that holds the Terraform state of the main repository.
#
# One independent switch:
#   create_state_bucket       -> create the bucket here
#
# They are separate on purpose. A common case is a bucket that already exists
# and is owned by another team: you keep creation off and turn the grant on.
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "tfstate" {
  # count acts as the on/off switch. 1 = create the bucket, 0 = skip it.
  count = var.create_state_bucket ? 1 : 0

  project  = google_project.host.project_id
  name     = var.state_bucket_name
  location = var.state_bucket_location

  # Disables per-object ACLs so access is governed by bucket level IAM only
  uniform_bucket_level_access = true

  # Never allow anonymous or public access to state files
  public_access_prevention = "enforced"

  # Object versioning lets you recover a previous state file if an apply
  # corrupts or truncates it
  versioning {
    enabled = true
  }

  # Keeps only the 10 most recent noncurrent versions of each object so old
  # state generations do not accumulate cost forever
  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  # Guards against an accidental terraform destroy wiping the state of the
  # main repository. Set it to false in code before any intentional removal.
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.required]
}

resource "time_sleep" "wait_for_bucket" {
  count           = var.create_state_bucket ? 1 : 0
  create_duration = "20s"
  # Explicit edge: the timer starts only after the bucket resource completes
  depends_on = [google_storage_bucket.tfstate]
}


# Bucket scoped grant for the deployer service account.
# roles/storage.objectUser covers get, list, create and delete of objects,
# which is everything the gcs backend needs, without any bucket administration.
resource "google_storage_bucket_iam_member" "tf_deployer_state" {
  count = var.create_state_bucket ? 1 : 0

  bucket = var.state_bucket_name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.tf_deployer.email}"
  depends_on = [
    time_sleep.wait_for_bucket,
    google_storage_bucket.tfstate,
  ]
}

