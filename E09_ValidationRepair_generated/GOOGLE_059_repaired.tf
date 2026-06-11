provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
  labels = {
    environment = "example"
    created_by  = "terraform"
  }
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
  labels = {
    environment = "example"
    created_by  = "terraform"
  }
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
}

variable "topic_name" {
  type        = string
}

variable "subscription_name" {
  type        = string
}

variable "publisher_members" {
  type        = list(string)
  sensitive   = true
}

variable "subscriber_members" {
  type        = list(string)
  sensitive   = true
}

output "topic_id" {
  value       = google_pubsub_topic.example.id
  description = "The ID of the Pub/Sub topic"
}

output "topic_name" {
  value       = google_pubsub_topic.example.name
  description = "The name of the Pub/Sub topic"
}

output "subscription_id" {
  value       = google_pubsub_subscription.example.id
  description = "The ID of the Pub/Sub subscription"
}

output "subscription_name" {
  value       = google_pubsub_subscription.example.name
  description = "The name of the Pub/Sub subscription"
}

output "publisher_iam_binding" {
  value       = google_project_iam_binding.pubsub_publisher.etag
  description = "The etag of the Pub/Sub publisher IAM binding"
}

output "subscriber_iam_binding" {
  value       = google_project_iam_binding.pubsub_subscriber.etag
  description = "The etag of the Pub/Sub subscriber IAM binding"
}