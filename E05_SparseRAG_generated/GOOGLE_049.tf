/*
 * Terraform networking resources for GCP.
 */

variable "gcp_region" {}
variable "gcp_network_name" {}
variable "gcp_subnet1_cidr" {}
variable "vpn_gateway_name" {}
variable "vpn_tunnel_name" {}
variable "bgp_session_name" {}
variable "bgp_asn" {}
variable "bgp_hold_time" {}
variable "bgp_keepalive_interval" {}
variable "peer_ip_address" {}
variable "router_ip_address" {}

resource "google_compute_network" "gcp-network" {
  name = var.gcp_network_name
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "gcp-subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = var.gcp_subnet1_cidr
  network       = google_compute_network.gcp-network.name
  region        = var.gcp_region
}

resource "google_compute_address" "gcp-vpn-ip" {
  name   = "gcp-vpn-ip"
  region = var.gcp_region
}

resource "google_compute_vpn_gateway" "gcp-vpn-gw" {
  name    = var.vpn_gateway_name
  network = google_compute_network.gcp-network.self_link
  region  = var.gcp_region
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.gcp-vpn-ip.address
  target      = google_compute_vpn_gateway.gcp-vpn-gw.self_link
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500-500"
  ip_address  = google_compute_address.gcp-vpn-ip.address
  target      = google_compute_vpn_gateway.gcp-vpn-gw.self_link
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500-4500"
  ip_address  = google_compute_address.gcp-vpn-ip.address
  target      = google_compute_vpn_gateway.gcp-vpn-gw.self_link
}

resource "google_compute_vpn_tunnel" "gcp-vpn-tunnel" {
  name               = var.vpn_tunnel_name
  region             = var.gcp_region
  vpn_gateway        = google_compute_vpn_gateway.gcp-vpn-gw.id
  peer_ip            = var.peer_ip_address
  shared_secret      = "your-shared-secret"
  ike_version        = 2
  target_vpn_gateway = google_compute_vpn_gateway.gcp-vpn-gw.id
}

resource "google_compute_external_vpn_gateway" "gcp-external-vpn-gw" {
  name            = "gcp-external-vpn-gw"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.peer_ip_address
  }
}

resource "google_compute_router" "gcp-router" {
  name    = "gcp-router"
  region  = var.gcp_region
  network = google_compute_network.gcp-network.id
}

resource "google_compute_router_interface" "gcp-router-interface" {
  name       = "gcp-router-interface"
  router     = google_compute_router.gcp-router.name
  region     = var.gcp_region
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.gcp-vpn-tunnel.name
}

resource "google_compute_router_peer" "gcp-router-peer" {
  name                      = var.bgp_session_name
  router                    = google_compute_router.gcp-router.name
  region                    = var.gcp_region
  peer_ip_address           = var.router_ip_address
  peer_asn                  = var.bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-router-interface.name
}

resource "google_compute_router_bgp_peer" "gcp-router-bgp-peer" {
  name                      = var.bgp_session_name
  router                    = google_compute_router.gcp-router.name
  region                    = var.gcp_region
  peer_group_name           = "gcp-router-peer-group"
  peer_asn                  = var.bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-router-interface.name
  max_propagation_distance  = 200
}