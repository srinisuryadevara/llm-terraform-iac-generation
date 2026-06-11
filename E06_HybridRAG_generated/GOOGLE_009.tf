variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_network_name" {
  type = string
}

variable "gcp_vpn_gateway_name" {
  type = string
}

variable "gcp_vpn_tunnel_name" {
  type = string
}

variable "gcp_vpn_tunnel_ip" {
  type = string
}

variable "gcp_vpn_tunnel_pre_shared_key" {
  type = string
  sensitive = true
}

variable "gcp_bgp_session_name" {
  type = string
}

variable "gcp_bgp_session_peer_asn" {
  type = number
}

variable "gcp_bgp_session_peer_ip" {
  type = string
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_network" "gcp_network" {
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "${var.gcp_network_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.gcp_network.name
  region        = var.gcp_region
}

resource "google_compute_address" "gcp_vpn_ip" {
  name   = "gcp-vpn-ip"
  region = var.gcp_region
}

resource "google_compute_vpn_gateway" "gcp_vpn_gateway" {
  name    = var.gcp_vpn_gateway_name
  network = google_compute_network.gcp_network.self_link
  region  = var.gcp_region
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.gcp_vpn_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500-500"
  ip_address  = google_compute_address.gcp_vpn_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500-4500"
  ip_address  = google_compute_address.gcp_vpn_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_vpn_tunnel" "gcp_vpn_tunnel" {
  name                  = var.gcp_vpn_tunnel_name
  region                = var.gcp_region
  ip_address           = google_compute_address.gcp_vpn_ip.address
  target_vpn_gateway   = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
  shared_secret        = var.gcp_vpn_tunnel_pre_shared_key
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]
  ike_version = 1
}

resource "google_compute_external_vpn_gateway" "gcp_external_vpn_gateway" {
  name            = "gcp-external-vpn-gateway"
  redundancy_type = "SINGLE_IP_INTERNALLY_ACCESSIBLE"
  interfaces {
    ip_address = var.gcp_vpn_tunnel_ip
  }
}

resource "google_compute_router" "gcp_router" {
  name    = "gcp-router"
  region  = var.gcp_region
  network = google_compute_network.gcp_network.name
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_interface" "gcp_router_interface" {
  name       = "gcp-router-interface"
  router     = google_compute_router.gcp_router.name
  region     = var.gcp_region
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.gcp_vpn_tunnel.name
}

resource "google_compute_router_peer" "gcp_router_peer" {
  name                      = var.gcp_bgp_session_name
  router                    = google_compute_router.gcp_router.name
  region                    = var.gcp_region
  peer_ip_address           = var.gcp_bgp_session_peer_ip
  peer_asn                  = var.gcp_bgp_session_peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp_router_interface.name
}