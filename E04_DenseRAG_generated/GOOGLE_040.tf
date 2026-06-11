# Configure the Google Cloud Provider
provider "google" {
  project = var.project
  region  = var.region
}

# Define the IAM service account bindings
variable "iam_assignments" {
  type = list(string)
}

variable "iam_assignments_count" {
  type = number
}

# Verify that iam_assignments_count matches the number of entries in iam_assignments
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

# Create a service account
resource "google_service_account" "example" {
  account_id   = "example-service-account"
  display_name = "Example Service Account"
}

# Define the IAM policy bindings
resource "google_service_account_iam_binding" "example" {
  count = var.iam_assignments_count

  service_account_id = google_service_account.example.id
  role               = split("=", element(var.iam_assignments, count.index))[1]
  members            = [split("=", element(var.iam_assignments, count.index))[0]]
}

# Example usage:
# iam_assignments = ["serviceAccount:example-service-account@example-project.iam.gserviceaccount.com=roles/iam.serviceAccountUser"]
# iam_assignments_count = 1