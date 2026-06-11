provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "example" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_name
  description                 = var.dataset_description
  location                    = var.region
  default_table_expiration_ms = var.default_table_expiration_ms

  labels = {
    env = var.env
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
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

  labels = {
    env = var.env
  }
}

resource "google_bigquery_dataset_iam_member" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role        = "roles/bigquery.dataViewer"
  member      = "user:${var.user_email}"
}

resource "google_bigquery_table_iam_member" "example" {
  table_id = "${google_bigquery_dataset.example.dataset_id}.${google_bigquery_table.example.table_id}"
  role     = "roles/bigquery.dataEditor"
  member   = "serviceAccount:${var.service_account_email}"
}