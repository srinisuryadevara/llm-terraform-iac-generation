variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account"
}

variable "iam_roles" {
  type        = list(string)
  description = "The list of IAM roles to bind to the service account"
}

resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = "Example Service Account"
}

resource "google_project_iam_member" "example" {
  for_each = toset(var.iam_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.example.email}"
}

resource "google_service_account_key" "example" {
  service_account_id = google_service_account.example.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

variable "iam_assignments" {
  type        = list(string)
  description = "The list of IAM assignments"
}

variable "iam_assignments_count" {
  type        = number
  description = "The number of IAM assignments"
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
    account = replace(element(var.iam_assignments, count.index), "@", "%40")
  }
}

locals {
  project = var.project_id
}

terraform {
  backend "gcs" {
    prefix = "example/state"
    bucket = "terraform-example"
  }
}

provider "google" {
  project = local.project
}

output "service_account_email" {
  value = google_service_account.example.email
}