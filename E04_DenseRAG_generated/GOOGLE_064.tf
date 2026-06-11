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
  description = "The ID of the project to create the Spanner instance in"
}

variable "region" {
  type        = string
  description = "The region to create the Spanner instance in"
}

variable "instance_id" {
  type        = string
  description = "The ID of the Spanner instance to create"
}

variable "database_id" {
  type        = string
  description = "The ID of the Spanner database to create"
}

variable "iam_assignments" {
  type        = list(string)
  description = "A list of IAM assignments for the Spanner instance and database"
}

variable "iam_assignments_count" {
  type        = number
  description = "The number of IAM assignments"
}

resource "google_spanner_instance" "default" {
  name          = var.instance_id
  config        = "regional-${var.region}"
  display_name  = "Spanner Instance"
  num_nodes     = 1
}

resource "google_spanner_database" "default" {
  instance = google_spanner_instance.default.name
  name     = var.database_id
  ddl {
    database = var.database_id
  }
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

resource "google_spanner_instance_iam_member" "default" {
  count = var.iam_assignments_count

  instance = google_spanner_instance.default.name
  role     = split("=", element(var.iam_assignments, count.index))[1]
  member   = split("=", element(var.iam_assignments, count.index))[0]
}

resource "google_spanner_database_iam_member" "default" {
  count = var.iam_assignments_count

  instance = google_spanner_instance.default.name
  database = google_spanner_database.default.name
  role     = split("=", element(var.iam_assignments, count.index))[1]
  member   = split("=", element(var.iam_assignments, count.index))[0]
}