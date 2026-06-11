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
resource "google_service_account" "example_service_account" {
  account_id = var.service_account_id
}

# Create a key for the service account
resource "google_service_account_key" "example_service_account_key" {
  service_account_id = google_service_account.example_service_account.id
}

# Create a IAM policy for the service account
resource "google_pubsub_topic_iam_policy" "example_topic_iam_policy" {
  topic      = google_pubsub_topic.example_topic.name
  policy_data = data.google_iam_policy.example_policy.policy_data
}

# Create a IAM policy for the subscription
resource "google_pubsub_subscription_iam_policy" "example_subscription_iam_policy" {
  subscription = google_pubsub_subscription.example_subscription.name
  policy_data  = data.google_iam_policy.example_policy.policy_data
}

# Create a IAM policy
data "google_iam_policy" "example_policy" {
  binding {
    role = "roles/pubsub.publisher"
    members = [
      "serviceAccount:${google_service_account.example_service_account.email}",
    ]
  }
  binding {
    role = "roles/pubsub.subscriber"
    members = [
      "serviceAccount:${google_service_account.example_service_account.email}",
    ]
  }
}

# Create a IAM role for the service account
resource "google_project_iam_member" "example_project_iam_member" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.example_service_account.email}"
}

resource "google_project_iam_member" "example_project_iam_member_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.example_service_account.email}"
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
  description = "The name of the topic"
}

variable "subscription_name" {
  type        = string
  description = "The name of the subscription"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account"
}