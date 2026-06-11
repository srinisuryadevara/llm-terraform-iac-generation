provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "default" {
  name        = "default-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.default.self_link]
}

resource "google_compute_health_check" "default" {
  name               = "default-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

resource "google_compute_url_map" "default" {
  name            = "default-url-map"
  default_service = google_compute_backend_service.default.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_service.default.self_link
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "default-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "default-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}