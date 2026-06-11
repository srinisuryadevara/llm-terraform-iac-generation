provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create resources in"
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS managed zone"
}

variable "dns_zone_dns_name" {
  type        = string
  description = "The DNS name of the DNS managed zone"
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_dns_name
  description = "Example DNS managed zone"
  labels = {
    environment = "example"
  }
}

resource "google_dns_record_set" "example_a" {
  name         = "example.${google_dns_managed_zone.example.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = ["10.0.0.1"]
  project      = var.project_id
}

resource "google_dns_record_set" "example_cname" {
  name         = "cname.example.${google_dns_managed_zone.example.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = ["example.com."]
  project      = var.project_id
}