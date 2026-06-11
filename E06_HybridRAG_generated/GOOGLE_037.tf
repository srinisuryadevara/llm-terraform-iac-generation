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
  type      = string
  sensitive = true
}

variable "gcp_vpn_tunnel_bgp_session_peer_asn" {
  type = number
}

variable "gcp_vpn_tunnel_bgp_session_peer_address" {
  type = string
}

variable "gcp_vpn_tunnel_bgp_session_local_asn" {
  type = number
}

variable "gcp_vpn_tunnel_bgp_session_local_address" {
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

resource "google_compute_subnetwork" "gcp_subnetwork" {
  name          = "${var.gcp_network_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.gcp_network.name
  region        = var.gcp_region
}

resource "google_compute_address" "gcp_vpn_gateway_ip" {
  name   = "gcp-vpn-gateway-ip"
  region = var.gcp_region
}

resource "google_compute_vpn_gateway" "gcp_vpn_gateway" {
  name    = var.gcp_vpn_gateway_name
  network = google_compute_network.gcp_network.self_link
  region  = var.gcp_region
}

resource "google_compute_forwarding_rule" "gcp_vpn_gateway_esp" {
  name        = "gcp-vpn-gateway-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.gcp_vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "gcp_vpn_gateway_udp500" {
  name        = "gcp-vpn-gateway-udp500"
  ip_protocol = "UDP"
  ports       = [500]
  ip_address  = google_compute_address.gcp_vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "gcp_vpn_gateway_udp4500" {
  name        = "gcp-vpn-gateway-udp4500"
  ip_protocol = "UDP"
  ports       = [4500]
  ip_address  = google_compute_address.gcp_vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_vpn_tunnel" "gcp_vpn_tunnel" {
  name                  = var.gcp_vpn_tunnel_name
  region                = var.gcp_region
  vpn_gateway           = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
  peer_ip               = var.gcp_vpn_tunnel_ip
  shared_secret         = var.gcp_vpn_tunnel_pre_shared_key
  ike_version           = 2
  target_vpn_gateway    = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]
}

resource "google_compute_external_vpn_gateway" "gcp_external_vpn_gateway" {
  name            = "gcp-external-vpn-gateway"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.gcp_vpn_tunnel_ip
  }
}

resource "google_compute_router" "gcp_router" {
  name    = "gcp-router"
  region  = var.gcp_region
  network = google_compute_network.gcp_network.name
}

resource "google_compute_router_interface" "gcp_router_interface" {
  name       = "gcp-router-interface"
  router     = google_compute_router.gcp_router.name
  region     = var.gcp_region
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.gcp_vpn_tunnel.name
}

resource "google_compute_router_peer" "gcp_router_peer" {
  name                      = "gcp-router-peer"
  router                    = google_compute_router.gcp_router.name
  region                    = var.gcp_region
  peer_ip_address           = var.gcp_vpn_tunnel_bgp_session_peer_address
  peer_asn                  = var.gcp_vpn_tunnel_bgp_session_peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp_router_interface.name
}

resource "google_compute_router_bgp_peer" "gcp_router_bgp_peer" {
  name                      = "gcp-router-bgp-peer"
  router                    = google_compute_router.gcp_router.name
  region                    = var.gcp_region
  peer_group                = "gcp-router-peer"
  advertised_ip_ranges {
    range = "10.0.0.0/24"
  }
  advertised_ip_ranges {
    range = "0.0.0.0/0"
  }
}