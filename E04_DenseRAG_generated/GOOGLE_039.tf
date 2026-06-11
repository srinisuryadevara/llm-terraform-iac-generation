terraform {
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
    null = {
      version = ">= 2.1.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "instance_id" {
  type        = string
  description = "The ID of the Spanner instance"
}

variable "database_id" {
  type        = string
  description = "The ID of the Spanner database"
}

variable "iam_assignments" {
  type        = list(string)
  description = "A list of IAM assignments in the format 'account-specifier=iam-role'"
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

resource "google_spanner_instance" "default" {
  name          = var.instance_id
  config        = "regional-${var.region}"
  display_name  = "Spanner instance"
  num_nodes     = 1
}

resource "google_spanner_database" "default" {
  instance = google_spanner_instance.default.name
  name     = var.database_id
  ddl {
    database = var.database_id
  }
}

resource "google_spanner_database_iam_member" "default" {
  count = var.iam_assignments_count

  database = google_spanner_database.default.name
  role      = split("=", element(var.iam_assignments, count.index))[1]
  member    = split("=", element(var.iam_assignments, count.index))[0]
}