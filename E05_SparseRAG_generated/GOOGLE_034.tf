provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the DNS zone in"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to create the DNS zone in"
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS zone to create"
}

variable "dns_zone_dns_name" {
  type        = string
  description = "The DNS name of the DNS zone to create"
}

variable "a_record_name" {
  type        = string
  description = "The name of the A record to create"
}

variable "a_record_value" {
  type        = string
  description = "The value of the A record to create"
}

variable "cname_record_name" {
  type        = string
  description = "The name of the CNAME record to create"
}

variable "cname_record_value" {
  type        = string
  description = "The value of the CNAME record to create"
}

resource "google_dns_managed_zone" "dns_zone" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_dns_name
  description = "Managed DNS zone for ${var.dns_zone_name}"
}

resource "google_dns_record_set" "a_record" {
  name         = "${var.a_record_name}.${google_dns_managed_zone.dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas      = [var.a_record_value]
}

resource "google_dns_record_set" "cname_record" {
  name         = "${var.cname_record_name}.${google_dns_managed_zone.dns_zone.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas      = [var.cname_record_value]
}