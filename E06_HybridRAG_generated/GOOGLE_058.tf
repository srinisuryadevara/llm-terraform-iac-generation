variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "dataset_id" {
  type        = string
  description = "BigQuery dataset ID"
}

variable "table_id" {
  type        = string
  description = "BigQuery table ID"
}

variable "location" {
  type        = string
  description = "BigQuery dataset location"
}

variable "access_role" {
  type        = string
  description = "Access role for the dataset"
}

variable "access_special_group" {
  type        = string
  description = "Special group for access control"
}

provider "google" {
  project = var.project
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.location

  access {
    special_group = var.access_special_group
    role          = var.access_role
  }

  labels = {
    environment = "dev"
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

  labels = {
    environment = "dev"
  }
}