provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
  labels = {
    environment = var.environment
  }
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
  labels = {
    environment = var.environment
  }
}

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_project_iam_binding" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "topic_name" {
  type        = string
  description = "The name of the Pub/Sub topic"
}

variable "subscription_name" {
  type        = string
  description = "The name of the Pub/Sub subscription"
}

variable "environment" {
  type        = string
  description = "The environment of the resources"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}