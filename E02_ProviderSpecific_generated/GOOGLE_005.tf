provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_service" "default" {
  name     = "cloudrun-srv"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffic {
    percent         = 50
    latest_revision = true
  }

  traffic {
    percent = 50
    revision = google_cloud_run_revision.default.name
  }
}

resource "google_cloud_run_revision" "default" {
  service_name = google_cloud_run_service.default.name
  location      = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = var.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members = [
    "user:${var.invoker_email}",
  ]
}