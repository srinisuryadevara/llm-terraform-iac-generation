provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region for the resources"
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS zone"
}

variable "dns_zone_dns_name" {
  type        = string
  description = "The DNS name of the DNS zone"
}

variable "a_record_name" {
  type        = string
  description = "The name of the A record"
}

variable "a_record_ip" {
  type        = string
  description = "The IP address of the A record"
}

variable "cname_record_name" {
  type        = string
  description = "The name of the CNAME record"
}

variable "cname_record_dns_name" {
  type        = string
  description = "The DNS name of the CNAME record"
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_dns_name
  description = "Example DNS zone"
  labels = {
    environment = "example"
  }
}

resource "google_dns_record_set" "a_record" {
  name         = google_dns_managed_zone.example.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.a_record_ip]
  labels = {
    environment = "example"
  }
}

resource "google_dns_record_set" "cname_record" {
  name         = "${var.cname_record_name}.${google_dns_managed_zone.example.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.cname_record_dns_name]
  labels = {
    environment = "example"
  }
}