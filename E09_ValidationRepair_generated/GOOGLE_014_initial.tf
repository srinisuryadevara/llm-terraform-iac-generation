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
  sensitive   = true
}

variable "dns_zone_name" {
  type        = string
}

variable "dns_zone_dns_name" {
  type        = string
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_dns_name
  description = "Example DNS zone"
}

resource "google_dns_record_set" "a_record" {
  name         = "example.${google_dns_managed_zone.example.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name

  rrdatas = [
    "192.0.2.1",
    "198.51.100.1",
  ]
}

resource "google_dns_record_set" "cname_record" {
  name         = "cname.example.${google_dns_managed_zone.example.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name

  rrdatas = [
    "example.com.",
  ]
}