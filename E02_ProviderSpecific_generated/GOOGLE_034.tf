provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_domain
  description = "Example DNS managed zone"
}

resource "google_dns_record_set" "a_record" {
  name         = var.a_record_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdata       = [var.a_record_ip]
}

resource "google_dns_record_set" "cname_record" {
  name         = var.cname_record_name
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdata       = [var.cname_record_domain]
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "dns_zone_domain" {
  type = string
}

variable "a_record_name" {
  type = string
}

variable "a_record_ip" {
  type = string
}

variable "cname_record_name" {
  type = string
}

variable "cname_record_domain" {
  type = string
}