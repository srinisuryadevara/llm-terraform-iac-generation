provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "example" {
  name = var.topic_name
  labels = {
    environment = var.environment
    application = var.application
  }
}

resource "google_pubsub_subscription" "example" {
  name  = var.subscription_name
  topic = google_pubsub_topic.example.name
  labels = {
    environment = var.environment
    application = var.application
  }
}

resource "google_service_account" "example" {
  account_id = var.service_account_id
  description = "Service account for Pub/Sub"
  labels = {
    environment = var.environment
    application = var.application
  }
}

resource "google_project_iam_member" "example" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.example.email}"
}

resource "google_project_iam_member" "example_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.example.email}"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "topic_name" {
  type        = string
  description = "Pub/Sub topic name"
}

variable "subscription_name" {
  type        = string
  description = "Pub/Sub subscription name"
}

variable "service_account_id" {
  type        = string
  description = "Service account ID"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "application" {
  type        = string
  description = "Application"
}