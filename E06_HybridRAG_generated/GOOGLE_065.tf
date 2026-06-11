variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "service_name" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "image_url" {
  type = string
}

variable "traffic_split" {
  type = map(string)
}

variable "iam_members" {
  type = list(string)
}

variable "iam_role" {
  type = string
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.location

  template {
    metadata {
      annotations = {
        "run.googleapis.com/ingress" = "all"
      }
    }

    spec {
      service_account_name = var.service_account_email
      containers {
        image = var.image_url
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = var.traffic_split["percent"]
    latest_revision = var.traffic_split["latest_revision"]
  }
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = google_cloud_run_service.main.location
  service  = google_cloud_run_service.main.name
  role     = var.iam_role
  members  = var.iam_members
}