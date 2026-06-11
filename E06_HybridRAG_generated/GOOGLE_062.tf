variable "project_id" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account to create"
}

variable "iam_roles" {
  type        = list(string)
  description = "The list of IAM roles to bind to the service account"
}

variable "members" {
  type        = list(string)
  description = "The list of members to bind to the service account"
}

resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = "Example Service Account"
  description  = "Example service account for demonstration purposes"
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

resource "null_resource" "verify_iam_roles_count" {
  provisioner "local-exec" {
    command = <<EOF
if [ ${length(var.iam_roles)} -ne ${length(var.iam_roles)} ]; then
  echo "var.iam_roles must match the length of var.iam_roles list"
  exit 1
fi
EOF
  }

  triggers {
    iam_roles_computed = "${length(var.iam_roles)}"
  }
}

output "service_account_email" {
  value       = google_service_account.example.email
  description = "The email address of the service account"
}

output "service_account_id" {
  value       = google_service_account.example.id
  description = "The ID of the service account"
}