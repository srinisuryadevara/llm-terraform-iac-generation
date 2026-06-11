# Store state in a Cloud Storage bucket
terraform {
  backend "gcs" {
    bucket  = var.bucket_name
    prefix  = "terraform/state/dns"
    project = var.project_id
  }
}

# Initialize the Google providers
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = "${var.region}-${var.zone}"
}

# Create DNS zone
resource "google_dns_managed_zone" "external" {
  name        = var.project_name
  dns_name    = var.dns_zone
  description = "External DNS zone"
}

# Create A record
resource "google_dns_record_set" "a_record" {
  name         = var.a_record_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external.name
  rrdatas      = [var.a_record_value]
}

# Create CNAME record
resource "google_dns_record_set" "cname_record" {
  name         = var.cname_record_name
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external.name
  rrdatas      = [var.cname_record_value]
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "project_name" {
  type        = string
}

variable "dns_zone" {
  type        = string
}

variable "region" {
  type        = string
}

variable "zone" {
  type        = string
}

variable "a_record_name" {
  type        = string
}

variable "a_record_value" {
  type        = string
}

variable "cname_record_name" {
  type        = string
}

variable "cname_record_value" {
  type        = string
}