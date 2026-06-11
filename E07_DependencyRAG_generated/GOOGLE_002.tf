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
  description = "The default lifetime of a table in the dataset, in milliseconds"
}

variable "labels" {
  type        = map(string)
  description = "A map of labels to apply to the BigQuery dataset"
}

variable "access_special_group" {
  type        = string
  description = "The special group to grant access to the BigQuery dataset"
}

variable "access_role" {
  type        = string
  description = "The role to grant to the special group"
}

variable "access_user_by_email" {
  type        = string
  description = "The email address of the user to grant access to the BigQuery dataset"
}

variable "access_user_role" {
  type        = string
  description = "The role to grant to the user"
}

variable "access_group_by_email" {
  type        = string
  description = "The email address of the group to grant access to the BigQuery dataset"
}

variable "access_group_role" {
  type        = string
  description = "The role to grant to the group"
}

variable "access_domain" {
  type        = string
  description = "The domain to grant access to the BigQuery dataset"
}

variable "access_domain_role" {
  type        = string
  description = "The role to grant to the domain"
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
  labels                      = var.labels
  location                    = var.location

  access {
    special_group = var.access_special_group
    role          = var.access_role
  }

  access {
    user_by_email = var.access_user_by_email
    role          = var.access_user_role
  }

  access {
    group_by_email = var.access_group_by_email
    role          = var.access_group_role
  }

  access {
    domain         = var.access_domain
    role          = var.access_domain_role
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_name

  schema = jsonencode([
    {
      name = "column1"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "column2"
      type = "INTEGER"
      mode = "NULLABLE"
    }
  ])

  time_partitioning {
    type = "DAY"
  }

  clustering {
    fields = ["column1", "column2"]
  }

  expiration_time = 86400000 // 1 day in seconds
}