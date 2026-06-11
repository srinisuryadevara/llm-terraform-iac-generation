provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "instance_id" {
  type        = string
}

variable "database_id" {
  type        = string
}

variable "iam_member" {
  type = object({
    role   = string
    member = string
  })
}

resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = "regional-us-central1"
  display_name        = "Example Spanner Instance"
  num_nodes           = 1
}

resource "google_spanner_database" "example" {
  instance   = google_spanner_instance.example.name
  name        = var.database_id
  ddl {
    database = var.database_id
  }
}

resource "google_spanner_database_iam_member" "example" {
  database  = google_spanner_database.example.name
  role      = var.iam_member.role
  member    = var.iam_member.member
}

resource "google_spanner_instance_iam_member" "example" {
  instance  = google_spanner_instance.example.name
  role      = var.iam_member.role
  member    = var.iam_member.member
}