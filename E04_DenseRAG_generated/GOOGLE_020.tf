variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "dataset_id" {
  type        = string
  description = "The ID of the dataset"
}

variable "table_id" {
  type        = string
  description = "The ID of the table"
}

variable "location" {
  type        = string
  description = "The location of the dataset"
}

variable "description" {
  type        = string
  description = "The description of the dataset"
}

variable "access_special_group" {
  type        = string
  description = "The special group to grant access to"
}

variable "access_role" {
  type        = string
  description = "The role to grant to the special group"
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
    special_group = var.access_special_group
    role          = var.access_role
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

  clustering = [
    {
      field = "id"
    }
  ]

  partitioning = {
    type = "TIME"
    field = "created_at"
  }
}