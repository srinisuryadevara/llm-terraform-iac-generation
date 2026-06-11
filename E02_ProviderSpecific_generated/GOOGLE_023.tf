provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = "default-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.id]
}

resource "google_compute_health_check" "default" {
  name               = "default-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  http_health_check {
    port = 80
  }
}

resource "google_compute_security_policy" "default" {
  name        = "default-security-policy"
  description = "Default security policy"
}

resource "google_compute_security_policy_rule" "default" {
  security_policy = google_compute_security_policy.default.id
  priority        = 1000
  action          = "allow"
  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["0.0.0.0/0"]
    }
  }
}

resource "google_compute_backend_service_security_policy_association" "default" {
  security_policy = google_compute_security_policy.default.id
  service          = google_compute_backend_service.default.id
}