# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the Pub/Sub topic and subscription in"
}

variable "topic_name" {
  type        = string
  description = "The name of the Pub/Sub topic to create"
}

variable "subscription_name" {
  type        = string
  description = "The name of the Pub/Sub subscription to create"
}

variable "service_account_email" {
  type        = string
  description = "The email address of the service account to grant IAM permissions to"
}

resource "google_pubsub_topic" "example" {
  project = var.project_id
  name    = var.topic_name
}

resource "google_pubsub_subscription" "example" {
  project = var.project_id
  name    = var.subscription_name
  topic   = google_pubsub_topic.example.name
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