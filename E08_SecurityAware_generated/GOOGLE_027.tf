provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create resources in"
}

variable "topic_name" {
  type        = string
  description = "The name of the Pub/Sub topic"
}

variable "subscription_name" {
  type        = string
  description = "The name of the Pub/Sub subscription"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account to grant permissions to"
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
  labels = {
    environment = "example"
  }
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
  labels = {
    environment = "example"
  }
}

resource "google_service_account" "example" {
  account_id = "example-service-account"
  description = "Example service account"
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