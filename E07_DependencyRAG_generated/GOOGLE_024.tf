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
resource "google_service_account" "example" {
  account_id = var.service_account_id
}

# Create a key for the service account
resource "google_service_account_key" "example" {
  service_account_id = google_service_account.example.id
}

# Create a IAM policy for Pub/Sub publisher
resource "google_iam_policy" "publisher" {
  name        = var.publisher_policy_name
  description = "Pub/Sub publisher policy"

  policy_data = jsonencode({
    bindings = [
      {
        role = "roles/pubsub.publisher"
        members = [
          "serviceAccount:${google_service_account.example.email}",
        ]
      },
    ]
  })
}

# Create a IAM policy for Pub/Sub subscriber
resource "google_iam_policy" "subscriber" {
  name        = var.subscriber_policy_name
  description = "Pub/Sub subscriber policy"

  policy_data = jsonencode({
    bindings = [
      {
        role = "roles/pubsub.subscriber"
        members = [
          "serviceAccount:${google_service_account.example.email}",
        ]
      },
    ]
  })
}

# Attach the IAM policies to the service account
resource "google_service_account_iam_policy" "publisher" {
  service_account_id = google_service_account.example.id
  policy            = google_iam_policy.publisher.policy_data
}

resource "google_service_account_iam_policy" "subscriber" {
  service_account_id = google_service_account.example.id
  policy            = google_iam_policy.subscriber.policy_data
}

# Create a IAM binding for the Pub/Sub topic
resource "google_pubsub_topic_iam_binding" "publisher" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

resource "google_pubsub_topic_iam_binding" "subscriber" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

# Create a IAM binding for the Pub/Sub subscription
resource "google_pubsub_subscription_iam_binding" "subscriber" {
  subscription = google_pubsub_subscription.example.name
  role         = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
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

variable "service_account_id" {
  type = string
}

variable "publisher_policy_name" {
  type = string
}

variable "subscriber_policy_name" {
  type = string
}