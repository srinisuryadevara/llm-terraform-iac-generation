provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
      }
    }
  }

  traffic {
    percent         = 50
    latest_revision = true
  }

  traffic {
    percent = 50
    revision_name = google_cloud_run_revision.revision.name
  }
}

resource "google_cloud_run_revision" "revision" {
  service_name = google_cloud_run_service.default.name
  location     = var.region

  template {
    spec {
      containers {
        image = var.container_image
      }
    }
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = var.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members = [
    "user:${var.invoker_user}",
  ]
}