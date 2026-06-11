provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create resources in"
}

variable "dataset_id" {
  type        = string
  description = "The ID of the BigQuery dataset"
}

variable "table_id" {
  type        = string
  description = "The ID of the BigQuery table"
}

variable "iam_members" {
  type = list(object({
    role = string
    member = string
  }))
  description = "The IAM members to grant access to the BigQuery dataset"
}

resource "google_bigquery_dataset" "example" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.region

  labels = {
    env        = "prod"
    managed-by = "terraform"
  }

  access {
    role          = "OWNER"
    user_by_email = var.iam_members[0].member
  }

  access {
    role          = "READER"
    user_by_email = var.iam_members[1].member
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = var.table_id

  labels = {
    env        = "prod"
    managed-by = "terraform"
  }

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

  encryption_specification {
    kms_key_name = google_kms_crypto_key.example.id
  }
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
}

resource "google_kms_crypto_key_version" "example" {
  crypto_key = google_kms_crypto_key.example.id
}