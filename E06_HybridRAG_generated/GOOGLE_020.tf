variable "project" {
  type        = string
  sensitive   = true
}

variable "dataset_id" {
  type        = string
}

variable "table_id" {
  type        = string
}

variable "location" {
  type        = string
}

variable "description" {
  type        = string
}

variable "access_control_group" {
  type        = string
}

variable "access_control_role" {
  type        = string
}

provider "google" {
  project = var.project
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.location
  description = var.description

  access {
    special_group = var.access_control_group
    role          = var.access_control_role
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id

  time_partitioning {
    type = "DAY"
  }

  labels = {
    env = "dev"
  }
}