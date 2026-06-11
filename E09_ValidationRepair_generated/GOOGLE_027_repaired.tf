provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
  labels = {
    environment = "example"
    application = "pubsub"
  }
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
  labels = {
    environment = "example"
    application = "pubsub"
  }
}

resource "google_project_iam_member" "example" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.service_account_email}"
}

resource "google_project_iam_member" "example_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${var.service_account_email}"
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

variable "service_account_email" {
  type        = string
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

output "publisher_iam_member" {
  value       = google_project_iam_member.example.etag
  description = "The ETag of the Pub/Sub publisher IAM member"
}

output "subscriber_iam_member" {
  value       = google_project_iam_member.example_subscriber.etag
  description = "The ETag of the Pub/Sub subscriber IAM member"
}