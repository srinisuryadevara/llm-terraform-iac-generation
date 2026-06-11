provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.location

  labels = {
    env = var.env
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
}

resource "google_bigquery_dataset_iam_policy" "policy" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  policy_data = google_iam_policy.policy.policy_data
}

resource "google_iam_policy" "policy" {
  name        = var.policy_name
  description = var.policy_description

  policy_data = <<EOF
{
  "version": 3,
  "bindings": [
    {
      "role": "roles/bigquery.dataViewer",
      "members": [
        "user:${var.user_email}"
      ]
    },
    {
      "role": "roles/bigquery.dataEditor",
      "members": [
        "serviceAccount:${var.service_account_email}"
      ]
    }
  ]
}
EOF
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "location" {
  type = string
}

variable "env" {
  type = string
}

variable "table_id" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "policy_description" {
  type = string
}

variable "user_email" {
  type = string
}

variable "service_account_email" {
  type = string
}