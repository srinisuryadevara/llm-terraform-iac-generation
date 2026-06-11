provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = "example-topic"
  labels = {
    environment = var.environment
  }
}

resource "google_pubsub_subscription" "example" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.name
  labels = {
    environment = var.environment
  }
}

resource "google_service_account" "example" {
  account_id = "example-service-account"
  description = "Example service account for Pub/Sub"
}

resource "google_project_iam_member" "example" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.example.email}"
}

resource "google_project_iam_member" "example_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.example.email}"
}

resource "google_pubsub_topic_iam_member" "example" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.example.email}"
}

resource "google_pubsub_subscription_iam_member" "example" {
  subscription = google_pubsub_subscription.example.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.example.email}"
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "environment" {
  type        = string
  description = "Environment name"
}