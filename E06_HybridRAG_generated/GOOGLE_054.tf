variable "project" {
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

variable "access_group" {
  type        = string
  description = "The access group for the dataset"
}

variable "access_role" {
  type        = string
  description = "The access role for the dataset"
}

provider "google" {
  project = var.project
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.location
  description = var.description

  access {
    special_group = var.access_group
    role          = var.access_role
  }

  labels = {
    env = "dev"
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id

  time_partitioning {
    type = "DAY"
  }

  cluster {
    fields = ["column1", "column2"]
  }

  labels = {
    env = "dev"
  }
}