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

# Create a service account for Pub/Sub
resource "google_service_account" "pubsub" {
  account_id = var.service_account_id
}

# Create a key for the service account
resource "google_service_account_key" "pubsub" {
  service_account_id = google_service_account.pubsub.id
}

# Create a IAM policy for the service account
resource "google_iam_policy" "pubsub" {
  name        = var.policy_name
  description = "Policy for Pub/Sub service account"

  policy_data = jsonencode({
    bindings = [
      {
        role = "roles/pubsub.publisher"
        members = [
          "serviceAccount:${google_service_account.pubsub.email}",
        ]
      },
      {
        role = "roles/pubsub.subscriber"
        members = [
          "serviceAccount:${google_service_account.pubsub.email}",
        ]
      },
    ]
  })
}

# Assign the IAM policy to the service account
resource "google_service_account_iam_policy" "pubsub" {
  service_account_id = google_service_account.pubsub.id
  policy            = google_iam_policy.pubsub.policy_data
}

# Create a IAM binding for the Pub/Sub topic
resource "google_pubsub_topic_iam_binding" "example" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.pubsub.email}",
  ]
}

# Create a IAM binding for the Pub/Sub subscription
resource "google_pubsub_subscription_iam_binding" "example" {
  subscription = google_pubsub_subscription.example.name
  role         = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.pubsub.email}",
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

variable "service_account_id" {
  type        = string
  description = "The ID of the service account"
}

variable "policy_name" {
  type        = string
  description = "The name of the IAM policy"
}