# Store state in a Cloud Storage bucket
terraform {
  backend "gcs" {
    bucket  = var.state_bucket
    prefix  = "terraform/state/dns"
    project = var.project_id
  }
}

# Initialize the Google providers
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = "${var.region}-${var.zone}"
}

# Create DNS zone
resource "google_dns_managed_zone" "external" {
  name        = var.project_name
  dns_name    = var.dns_zone
  description = "External DNS zone"
}

# Create A record
resource "google_dns_record_set" "a_record" {
  name         = "example.${google_dns_managed_zone.external.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external.name
  rrdatas      = [google_compute_address.gcp-ip.address]
}

# Create CNAME record
resource "google_dns_record_set" "cname_record" {
  name         = "cname.example.${google_dns_managed_zone.external.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external.name
  rrdatas      = ["example.${google_dns_managed_zone.external.dns_name}"]
}

# Create static IP address
resource "google_compute_address" "gcp-ip" {
  name = "gcp-vm-ip-${var.region}"
  region = var.region
}