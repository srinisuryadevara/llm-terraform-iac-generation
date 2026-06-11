variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "dns_zone_name" {
  type        = string
  description = "Cloud DNS managed zone name"
}

variable "dns_zone_dns_name" {
  type        = string
  description = "Cloud DNS managed zone DNS name"
}

variable "a_record_name" {
  type        = string
  description = "A record name"
}

variable "a_record_ip" {
  type        = string
  description = "A record IP address"
}

variable "cname_record_name" {
  type        = string
  description = "CNAME record name"
}

variable "cname_record_dns_name" {
  type        = string
  description = "CNAME record DNS name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev, prod)"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_dns_name
  description = "Example Cloud DNS managed zone"
  labels = {
    environment = var.environment
  }
}

resource "google_dns_record_set" "a_record" {
  name         = google_dns_managed_zone.example.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.a_record_ip]
  labels = {
    environment = var.environment
  }
}

resource "google_dns_record_set" "cname_record" {
  name         = "${var.cname_record_name}.${google_dns_managed_zone.example.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.cname_record_dns_name]
  labels = {
    environment = var.environment
  }
}