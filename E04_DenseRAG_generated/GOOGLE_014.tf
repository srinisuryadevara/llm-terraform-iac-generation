# Store state in a Cloud Storage bucket
terraform {
  backend "gcs" {
    bucket  = var.state_bucket
    prefix  = "terraform/state/dns"
    project = var.project_id
  }
}

# Initialize the Google providers
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create DNS zone
resource "google_dns_managed_zone" "external" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone
  description = "External DNS zone"
}

# Create A record
resource "google_dns_record_set" "a_record" {
  name         = var.a_record_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external.name
  rrdatas      = [var.a_record_ip]
}

# Create CNAME record
resource "google_dns_record_set" "cname_record" {
  name         = var.cname_record_name
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external.name
  rrdatas      = [var.cname_record_value]
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "zone" {
  type        = string
  description = "The zone of the project"
}

variable "state_bucket" {
  type        = string
  description = "The name of the state bucket"
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS zone"
}

variable "dns_zone" {
  type        = string
  description = "The DNS zone"
}

variable "a_record_name" {
  type        = string
  description = "The name of the A record"
}

variable "a_record_ip" {
  type        = string
  description = "The IP of the A record"
}

variable "cname_record_name" {
  type        = string
  description = "The name of the CNAME record"
}

variable "cname_record_value" {
  type        = string
  description = "The value of the CNAME record"
}