provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone_domain
  description = var.dns_zone_description
  labels      = var.dns_zone_labels
}

resource "google_dns_record_set" "a_record" {
  name         = var.a_record_name
  type         = "A"
  ttl          = var.a_record_ttl
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = var.a_record_values
}

resource "google_dns_record_set" "cname_record" {
  name         = var.cname_record_name
  type         = "CNAME"
  ttl          = var.cname_record_ttl
  managed_zone = google_dns_managed_zone.example.name
  rrdatas      = [var.cname_record_value]
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "dns_zone_name" {
  type        = string
}

variable "dns_zone_domain" {
  type        = string
}

variable "dns_zone_description" {
  type        = string
  default     = "Example DNS zone"
}

variable "dns_zone_labels" {
  type        = map(string)
  default     = {}
}

variable "a_record_name" {
  type        = string
}

variable "a_record_ttl" {
  type        = number
  default     = 300
}

variable "a_record_values" {
  type        = list(string)
}

variable "cname_record_name" {
  type        = string
}

variable "cname_record_ttl" {
  type        = number
  default     = 300
}

variable "cname_record_value" {
  type        = string
}