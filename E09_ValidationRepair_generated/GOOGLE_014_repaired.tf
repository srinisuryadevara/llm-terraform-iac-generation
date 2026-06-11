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
  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "google_dns_record_set" "a_record" {
  name         = "example.${google_dns_managed_zone.example.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  labels = {
    record_type = "A"
    managed_by  = "terraform"
  }

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
  labels = {
    record_type = "CNAME"
    managed_by  = "terraform"
  }

  rrdatas = [
    "example.com.",
  ]
}

output "dns_managed_zone_id" {
  value       = google_dns_managed_zone.example.id
  description = "The ID of the DNS managed zone"
}

output "dns_managed_zone_name" {
  value       = google_dns_managed_zone.example.name
  description = "The name of the DNS managed zone"
}

output "dns_managed_zone_dns_name" {
  value       = google_dns_managed_zone.example.dns_name
  description = "The DNS name of the DNS managed zone"
}

output "a_record_name" {
  value       = google_dns_record_set.a_record.name
  description = "The name of the A record"
}

output "cname_record_name" {
  value       = google_dns_record_set.cname_record.name
  description = "The name of the CNAME record"
}