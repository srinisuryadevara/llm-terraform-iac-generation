variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "service_name" {
  type = string
}

variable "traffic_split" {
  type = map(number)
}

variable "image_url" {
  type = string
}

variable "port" {
  type = number
}

variable "role" {
  type = string
}

variable "members" {
  type = list(string)
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.location

  template {
    spec {
      containers {
        image = var.image_url
        ports {
          container_port = var.port
        }
      }
    }
  }

  traffic {
    percent         = var.traffic_split["latest"]
    latest_revision = true
  }

  traffic {
    percent = var.traffic_split["previous"]
    revision = google_cloud_run_revision.previous.name
  }
}

resource "google_cloud_run_revision" "previous" {
  service = google_cloud_run_service.main.name
  depends_on = [google_cloud_run_service.main]
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = google_cloud_run_service.main.location
  service  = google_cloud_run_service.main.name
  role     = var.role
  members  = var.members
}