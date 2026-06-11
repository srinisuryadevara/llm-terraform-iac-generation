provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
}

resource "google_project_iam_binding" "example" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_project_iam_binding" "example_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to create resources in"
}

variable "topic_name" {
  type        = string
  default     = "example-topic"
  description = "The name of the Pub/Sub topic"
}

variable "subscription_name" {
  type        = string
  default     = "example-subscription"
  description = "The name of the Pub/Sub subscription"
}

variable "service_account_email" {
  type        = string
  sensitive   = true
  description = "The email of the service account to grant permissions to"
}