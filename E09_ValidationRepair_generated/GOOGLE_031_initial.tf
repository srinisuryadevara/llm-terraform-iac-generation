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

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = var.publisher_members
}

resource "google_project_iam_binding" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = var.subscriber_members
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "topic_name" {
  type        = string
  default     = "example-topic"
}

variable "subscription_name" {
  type        = string
  default     = "example-subscription"
}

variable "publisher_members" {
  type        = list(string)
  sensitive   = true
}

variable "subscriber_members" {
  type        = list(string)
  sensitive   = true
}