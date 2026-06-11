# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a Cloud Pub/Sub topic
resource "google_pubsub_topic" "example_topic" {
  name = var.topic_name
}

# Create a Cloud Pub/Sub subscription
resource "google_pubsub_subscription" "example_subscription" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example_topic.name
}

# Create a service account for Pub/Sub
resource "google_service_account" "pubsub_sa" {
  account_id = var.service_account_id
}

# Create a key for the service account
resource "google_service_account_key" "pubsub_sa_key" {
  service_account_id = google_service_account.pubsub_sa.id
}

# Create a IAM policy for the service account to publish to the topic
resource "google_pubsub_topic_iam_policy" "example_policy" {
  project     = var.project_id
  topic       = google_pubsub_topic.example_topic.name
  policy_data = data.google_iam_policy.example_policy.policy_data
}

# Create a IAM policy for the service account to pull from the subscription
resource "google_pubsub_subscription_iam_policy" "example_policy" {
  project     = var.project_id
  subscription = google_pubsub_subscription.example_subscription.name
  policy_data = data.google_iam_policy.example_policy.policy_data
}

# Define the IAM policy data
data "google_iam_policy" "example_policy" {
  binding {
    role = "roles/pubsub.publisher"
    members = [
      "serviceAccount:${google_service_account.pubsub_sa.email}",
    ]
  }
  binding {
    role = "roles/pubsub.subscriber"
    members = [
      "serviceAccount:${google_service_account.pubsub_sa.email}",
    ]
  }
}

# Define the variables
variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "topic_name" {
  type        = string
  description = "The name of the Pub/Sub topic"
}

variable "subscription_name" {
  type        = string
  description = "The name of the Pub/Sub subscription"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account"
}