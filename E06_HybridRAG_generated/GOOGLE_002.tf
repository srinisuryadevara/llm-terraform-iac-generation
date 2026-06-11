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

variable "access_control" {
  type = list(object({
    role          = string
    special_group = string
  }))
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.location
  description = var.description

  dynamic "access" {
    for_each = var.access_control
    content {
      role          = access.value.role
      special_group = access.value.special_group
    }
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

  clustering = [
    {
      field = "id"
    }
  ]

  expiration_time = 86400000
}