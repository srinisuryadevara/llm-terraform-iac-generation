# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a Cloud Pub/Sub topic
resource "google_pubsub_topic" "example" {
  name = var.topic_name
}

# Create a Cloud Pub/Sub subscription
resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
}

# Create a service account to manage Pub/Sub
resource "google_service_account" "pubsub" {
  account_id   = "pubsub-service-account"
  display_name = "Pub/Sub Service Account"
}

# Grant the service account permission to publish to the topic
resource "google_pubsub_topic_iam_member" "publisher" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.pubsub.email}"
}

# Grant the service account permission to pull from the subscription
resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = google_pubsub_subscription.example.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.pubsub.email}"
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "topic_name" {
  type        = string
  description = "The name of the Pub/Sub topic to create"
}

variable "subscription_name" {
  type        = string
  description = "The name of the Pub/Sub subscription to create"
}