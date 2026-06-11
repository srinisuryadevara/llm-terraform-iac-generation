provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = "example-topic"
}

resource "google_pubsub_subscription" "example" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.name
}

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_project_iam_binding" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_pubsub_topic_iam_binding" "publisher" {
  topic = google_pubsub_topic.example.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_pubsub_subscription_iam_binding" "subscriber" {
  subscription = google_pubsub_subscription.example.name
  role           = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}