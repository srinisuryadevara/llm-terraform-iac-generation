variable "name" {
  type        = string
  description = "Name of the load balancer"
}

variable "region" {
  type        = string
  description = "Region of the load balancer"
}

variable "domain_root" {
  type        = string
  description = "Domain root of the load balancer"
}

variable "project_id" {
  type        = string
  description = "Project ID of the load balancer"
}

resource "random_id" "tf_prefix" {
  byte_length = 4
}

resource "google_compute_subnetwork" "psc" {
  name          = "${var.name}-psc-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.psc.id
}

resource "google_compute_network" "psc" {
  name                    = "${var.name}-psc-network"
  auto_create_subnetworks = false
}

resource "google_compute_service_attachment" "self" {
  name        = "${var.name}-psc-${random_id.tf_prefix.hex}"
  description = "A service attachment to expose the internal load balancer for Private Service Connect"

  region = var.region

  domain_names = [var.domain_root]

  enable_proxy_protocol = false
  nat_subnets           = [google_compute_subnetwork.psc.id]
}

resource "google_compute_backend_service" "self" {
  name        = "${var.name}-backend-service"
  description = "A backend service for the load balancer"

  protocol = "HTTP"

  backend {
    group = google_compute_instance_group.self.id
  }

  health_checks = [google_compute_health_check.self.id]
}

resource "google_compute_instance_group" "self" {
  name        = "${var.name}-instance-group"
  description = "An instance group for the load balancer"

  zone = var.region
}

resource "google_compute_health_check" "self" {
  name        = "${var.name}-health-check"
  description = "A health check for the load balancer"

  check_interval_sec = 10
  timeout_sec        = 5
  unhealthy_threshold = 2

  http_health_check {
    port = 80
  }
}

resource "google_compute_url_map" "self" {
  name        = "${var.name}-url-map"
  description = "A URL map for the load balancer"

  default_service = google_compute_backend_service.self.id

  host_rule {
    hosts        = [var.domain_root]
    service      = google_compute_backend_service.self.id
  }

  path_matcher {
    name            = "path-matcher"
    default_service = google_compute_backend_service.self.id

    path_rule {
      paths   = ["/"]
      service = google_compute_backend_service.self.id
    }
  }
}

resource "google_compute_target_http_proxy" "self" {
  name        = "${var.name}-target-http-proxy"
  description = "A target HTTP proxy for the load balancer"

  url_map = google_compute_url_map.self.id
}

resource "google_compute_global_forwarding_rule" "self" {
  name        = "${var.name}-global-forwarding-rule"
  description = "A global forwarding rule for the load balancer"

  target     = google_compute_target_http_proxy.self.id
  port_range = "80"
}