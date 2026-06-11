terraform {
  backend "gcs" {
    bucket  = var.state_bucket
    prefix  = "terraform/state/dns"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_dns_managed_zone" "example" {
  name        = var.dns_zone_name
  dns_name    = var.dns_zone
  description = "Example DNS zone"
}

resource "google_dns_record_set" "a_record" {
  name         = "example.${var.dns_zone}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name

  rrdatas = [
    var.a_record_ip,
  ]
}

resource "google_dns_record_set" "cname_record" {
  name         = "cname.example.${var.dns_zone}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.example.name

  rrdatas = [
    var.cname_record_domain,
  ]
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS zone"
}

variable "dns_zone" {
  type        = string
  description = "The DNS zone"
}

variable "a_record_ip" {
  type        = string
  description = "The IP address of the A record"
}

variable "cname_record_domain" {
  type        = string
  description = "The domain of the CNAME record"
}

variable "state_bucket" {
  type        = string
  description = "The name of the state bucket"
}