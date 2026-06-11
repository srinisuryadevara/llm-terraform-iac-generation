provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "topic_name" {
  type = string
}

variable "subscription_name" {
  type = string
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
}

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
  ]
}

resource "google_project_iam_binding" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
  ]
}

resource "google_pubsub_topic_iam_binding" "example" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
  ]
}

resource "google_pubsub_subscription_iam_binding" "example" {
  subscription = google_pubsub_subscription.example.name
  role          = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
  ]
}