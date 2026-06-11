provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy the resources"
}

variable "allowed_cidr" {
  type        = string
  description = "The allowed CIDR for the security policy"
}

resource "google_compute_backend_service" "example" {
  name        = "example-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.example.self_link
  }

  tags = ["example-backend-service"]
}

resource "google_compute_instance_group" "example" {
  name        = "example-instance-group"
  zone        = "${var.region}-a"
  instances   = []
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_security_policy" "example" {
  name        = "example-security-policy"
  description = "Example security policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [var.allowed_cidr]
      }
    }
    description = "Allow traffic from the allowed CIDR"
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all other traffic"
  }
}

resource "google_compute_security_policy" "example-advanced" {
  name        = "example-advanced-security-policy"
  description = "Example advanced security policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [var.allowed_cidr]
      }
    }
    description = "Allow traffic from the allowed CIDR"
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all other traffic"
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

resource "google_compute_backend_service" "example-advanced" {
  name        = "example-advanced-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.example.self_link
  }

  security_policy {
    security_policy = google_compute_security_policy.example-advanced.self_link
  }

  tags = ["example-advanced-backend-service"]
}

resource "google_compute_target_https_proxy" "example" {
  name             = "example-target-https-proxy"
  url_map          = google_compute_url_map.example.self_link
  ssl_certificates = [google_compute_ssl_certificate.example.self_link]
  min_tls_version  = "TLS_1_2"
}

resource "google_compute_url_map" "example" {
  name            = "example-url-map"
  default_service = google_compute_backend_service.example.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.example.self_link
  }

  path_matcher {
    name            = "example-path-matcher"
    default_service = google_compute_backend_service.example.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.example.self_link
    }
  }
}

resource "google_compute_ssl_certificate" "example" {
  name        = "example-ssl-certificate"
  private_key = file("~/.ssh/example-ssl-key")
  certificate = file("~/.ssh/example-ssl-cert")
}