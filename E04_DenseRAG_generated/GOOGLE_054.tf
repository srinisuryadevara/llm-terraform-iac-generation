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
  default     = "US"
}

variable "description" {
  type        = string
  description = "The description of the BigQuery dataset"
  default     = "A BigQuery dataset"
}

variable "access_control_group" {
  type        = string
  description = "The access control group for the BigQuery dataset"
  default     = "allAuthenticatedUsers"
}

variable "access_control_role" {
  type        = string
  description = "The access control role for the BigQuery dataset"
  default     = "READER"
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
    special_group = var.access_control_group
    role          = var.access_control_role
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

  clustering = [
    {
      field = "id"
    }
  ]

  expiration_time = 2524604400000 // 30 years from now
}