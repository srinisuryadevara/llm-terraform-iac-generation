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
  description = "The group to grant access to the BigQuery dataset"
}

variable "access_control_role" {
  type        = string
  description = "The role to grant to the access control group"
  default     = "READER"
}

provider "google" {
  project = var.project_id
  region  = "US"
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

  schema = jsonencode([
    {
      name = "id"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "name"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])

  time_partitioning {
    type = "DAY"
  }

  clustering {
    fields = ["id"]
  }

  labels = {
    env = "dev"
  }
}