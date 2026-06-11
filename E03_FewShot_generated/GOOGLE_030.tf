variable "project_id" {
  type        = string
  sensitive   = true
}

variable "dns_zone_name" {
  type        = string
}

variable "dns_zone_dns_name" {
  type        = string
}

variable "a_record_name" {
  type        = string
}

variable "a_record_ip" {
  type        = string
}

variable "cname_record_name" {
  type        = string
}

variable "cname_record_domain" {
  type        = string
}

provider "google" {
  project = var.project_id
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_dns_name
  description = "Example DNS zone"
}

resource "google_dns_record_set" "a_record" {
  name         = google_dns_managed_zone.example.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.a_record_ip]
}

resource "google_dns_record_set" "cname_record" {
  name         = "${var.cname_record_name}.${google_dns_managed_zone.example.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.cname_record_domain]
}