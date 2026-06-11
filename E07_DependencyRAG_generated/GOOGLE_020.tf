variable "project" {
  type        = string
  description = "The ID of the project where the BigQuery dataset will be created"
}

variable "dataset_name" {
  type        = string
  description = "The name of the BigQuery dataset"
}

variable "table_name" {
  type        = string
  description = "The name of the BigQuery table"
}

variable "location" {
  type        = string
  description = "The location where the BigQuery dataset will be created"
}

variable "description" {
  type        = string
  description = "The description of the BigQuery dataset"
}

variable "default_table_expiration_ms" {
  type        = number
  description = "The default expiration time for tables in the dataset, in milliseconds"
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
  project = var.project
  region  = var.location
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_name
  friendly_name               = var.dataset_name
  description                 = var.description
  default_table_expiration_ms = var.default_table_expiration_ms
  location                    = var.location

  access {
    role          = var.access_role
    special_group = var.special_group
  }

  labels = {
    env = "dev"
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_name

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

  clustering = [
    {
      field = "id"
    }
  ]

  expiration_time = timeadd(timestamp(), "1h")

  labels = {
    env = "dev"
  }
}