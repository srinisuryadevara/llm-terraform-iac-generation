variable "project" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account to create"
}

variable "iam_bindings" {
  type        = list(object({ role = string, members = list(string) }))
  description = "A list of IAM bindings to apply to the service account"
}

provider "google" {
  project = var.project
}

resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = "Example Service Account"
}

resource "google_service_account_iam_binding" "example" {
  for_each = { for binding in var.iam_bindings : binding.role => binding }

  service_account_id = google_service_account.example.name
  role               = each.key
  members            = each.value.members
}

variable "iam_assignments_count" {
  type        = number
  description = "The number of IAM assignments to apply"
}

variable "iam_assignments" {
  type        = list(string)
  description = "A list of IAM assignments to apply, in the format 'member=role'"
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

resource "google_project_iam_binding" "example" {
  count = var.iam_assignments_count

  project = var.project
  role    = split("=", var.iam_assignments[count.index])[1]
  members = [split("=", var.iam_assignments[count.index])[0]]
}