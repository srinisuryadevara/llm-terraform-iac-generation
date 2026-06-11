variable "project" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account to create"
}

variable "iam_assignments" {
  type        = list(string)
  description = "A list of IAM assignments in the format 'account-specifier=iam-role'"
}

variable "iam_assignments_count" {
  type        = number
  description = "The number of IAM assignments"
}

provider "google" {
  project = var.project
}

resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = "Example Service Account"
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
    account = "${replace(element(var.iam_assignments, count.index), "=", "=")}"
  }
}

resource "google_project_iam_binding" "example" {
  count = var.iam_assignments_count

  project = var.project
  role    = split("=", element(var.iam_assignments, count.index))[1]
  members = ["serviceAccount:${google_service_account.example.email}"]
}