variable "project_id" {
  type        = string
  description = "The ID of the project where the BigQuery dataset will be created"
}

variable "dataset_id" {
  type        = string
  description = "The ID of the BigQuery dataset"
}

variable "table_id" {
  type        = string
  description = "The ID of the BigQuery table"
}

variable "location" {
  type        = string
  description = "The location where the BigQuery dataset will be created"
}

variable "description" {
  type        = string
  description = "The description of the BigQuery dataset"
}

variable "access_role" {
  type        = string
  description = "The role to be assigned to the special group"
}

variable "special_group" {
  type        = string
  description = "The special group to be assigned the role"
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.location
  description = var.description

  access {
    special_group = var.special_group
    role          = var.access_role
  }

  labels = {
    env      = "dev"
    project  = var.project_id
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "name",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF

  clustering = [
    {
      field = "id"
    }
  ]

  expiration_time = 8640000 // 100 days
}

resource "google_bigquery_dataset_iam_member" "member" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = var.access_role
  member     = var.special_group
}