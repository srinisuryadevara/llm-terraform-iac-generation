locals {
  project           = var.project
  location          = var.location
  topic_name        = var.topic_name
  subscription_name = var.subscription_name
}

variable "project" {
  type        = string
  description = "The ID of the project to create the topic and subscription in"
}

variable "location" {
  type        = string
  description = "The location of the project"
}

variable "topic_name" {
  type        = string
  description = "The name of the topic to create"
}

variable "subscription_name" {
  type        = string
  description = "The name of the subscription to create"
}

terraform {
  backend "gcs" {
    prefix = "pubsub/state"
    bucket = "terraform-pubsub"
  }
}

provider "google" {
  project = local.project
  region  = local.location
}

resource "google_pubsub_topic" "example" {
  name = local.topic_name
}

resource "google_pubsub_subscription" "example" {
  name  = local.subscription_name
  topic = google_pubsub_topic.example.name
}

resource "google_service_account" "pubsub" {
  account_id   = "pubsub"
  display_name = "pubsub"
}

resource "google_project_iam_member" "pubsub_publisher" {
  project = local.project
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.pubsub.email}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = local.project
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.pubsub.email}"
}