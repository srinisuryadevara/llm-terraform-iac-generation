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

# Create a service account to run the subscription
resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = var.service_account_name
}

# Grant the service account permission to pull from the subscription
resource "google_project_iam_member" "example" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.example.email}"
}

# Grant the service account permission to view the topic
resource "google_project_iam_member" "example_viewer" {
  project = var.project_id
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.example.email}"
}

# Grant the service account permission to publish to the topic
resource "google_project_iam_member" "example_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.example.email}"
}