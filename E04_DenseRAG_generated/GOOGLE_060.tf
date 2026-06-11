# Copyright 2024 Google LLC
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
  required_version = ">= 1.0.0"
}

# PROVIDERS
provider "google" {
  version = "~> 4.0"
  project = var.project
  region  = var.region
}

# VARIABLES
variable "project" {
  type        = string
  description = "The ID of the project to create the secret in"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to create the secret in"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret to create"
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "The value of the secret to create"
}

variable "members" {
  type        = list(string)
  description = "The members to bind to the secret"
}

# RESOURCES
resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_value
}

resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = "roles/secretmanager.secretAccessor"
  members    = var.members
}