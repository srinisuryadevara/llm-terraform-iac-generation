variable "project_id" {
  type        = string
  description = "The ID of the project to create the Cloud Run service in"
}

variable "location" {
  type        = string
  description = "The location to create the Cloud Run service in"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "image_url" {
  type        = string
  description = "The URL of the container image to use for the Cloud Run service"
}

variable "traffic_split" {
  type        = map(number)
  description = "A map of traffic splits, where the key is the version name and the value is the percentage of traffic to send to that version"
}

variable "iam_members" {
  type        = list(string)
  description = "A list of IAM members to bind to the Cloud Run service"
}

variable "iam_roles" {
  type        = list(string)
  description = "A list of IAM roles to bind to the Cloud Run service"
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.location

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }

  traffic {
    percent         = var.traffic_split["latest"]
    latest_revision = true
  }

  dynamic "traffic" {
    for_each = var.traffic_split
    content {
      percent = traffic.value
      revision = traffic.key
    }
  }
}

resource "google_cloud_run_service_iam_member" "default" {
  count  = length(var.iam_members)
  service = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role     = var.iam_roles[count.index]
  member   = var.iam_members[count.index]
}