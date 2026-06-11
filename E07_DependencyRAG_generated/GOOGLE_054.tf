variable "project_id" {
  type        = string
  description = "The ID of the project to create the BigQuery dataset in"
}

variable "dataset_id" {
  type        = string
  description = "The ID of the BigQuery dataset to create"
}

variable "table_id" {
  type        = string
  description = "The ID of the BigQuery table to create"
}

variable "location" {
  type        = string
  description = "The location of the BigQuery dataset"
}

variable "description" {
  type        = string
  description = "The description of the BigQuery dataset"
}

variable "default_table_expiration_ms" {
  type        = number
  description = "The default expiration time for tables in the dataset, in milliseconds"
}

variable "access_group" {
  type        = string
  description = "The group to grant access to the BigQuery dataset"
}

variable "access_role" {
  type        = string
  description = "The role to grant to the access group"
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_id
  description                 = var.description
  location                    = var.location
  default_table_expiration_ms = var.default_table_expiration_ms

  access {
    role          = var.access_role
    special_group = var.access_group
  }

  labels = {
    env = "dev"
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

  time_partitioning {
    type = "DAY"
  }

  cluster {
    fields = ["id"]
  }

  labels = {
    env = "dev"
  }
}