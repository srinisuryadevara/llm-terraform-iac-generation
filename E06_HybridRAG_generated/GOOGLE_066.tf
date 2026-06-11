variable "project_id" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "prefix" {
  type        = string
  description = "The prefix to use for the service account name"
}

variable "iam_assignments" {
  type        = list(string)
  description = "A list of IAM assignments in the format 'account-specifier=iam-role'"
}

variable "iam_assignments_count" {
  type        = number
  description = "The number of IAM assignments"
}

resource "google_service_account" "minimal_service_account" {
  account_id   = "${var.prefix}-minimal"
  display_name = "${var.prefix}-minimal"
  description  = "Service account with minimal required roles"
}

resource "google_project_iam_member" "minimal_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.minimal_service_account.email}"
}

resource "null_resource" "verify_iam_assignments_count" {
  provisioner "local-exec" {
    command = <<EOF
if [ ${var.iam_assignments_count} -ne ${length(var.iam_assignments)} ]; then
  echo "var.iam_assignments_count must match the length of var.iam_assignments list"
  exit 1
fi
EOF
  }

  triggers {
    iam_assignments_computed = "${length(var.iam_assignments)}"
    iam_assignments_provided = "${var.iam_assignments_count}"
  }
}

data "null_data_source" "iam_assignments" {
  count = var.iam_assignments_count

  inputs = {
    account = replace(element(var.iam_assignments, count.index), "=", "-")
  }
}