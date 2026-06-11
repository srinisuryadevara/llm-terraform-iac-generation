/*
 * Terraform networking resources for GCP.
 */

resource "google_compute_network" "gcp-network" {
  name = "gcp-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "gcp-subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = var.gcp_subnet1_cidr
  network       = google_compute_network.gcp-network.name
  region        = var.gcp_region
}

/*
 * ----------VPN Connection----------
 */

resource "google_compute_address" "gcp-vpn-ip" {
  name   = "gcp-vpn-ip"
  region = var.gcp_region
}

resource "google_compute_vpn_gateway" "gcp-vpn-gw" {
  name    = "gcp-vpn-gw-${var.gcp_region}"
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
  name                  = "gcp-vpn-tunnel"
  region                = var.gcp_region
  vpn_gateway           = google_compute_vpn_gateway.gcp-vpn-gw.self_link
  peer_ip               = var.vpn_peer_ip
  shared_secret         = var.vpn_shared_secret
  ike_version           = 2
  local_traffic_selector = [var.gcp_subnet1_cidr]
  remote_traffic_selector = [var.vpn_remote_cidr]
}

resource "google_compute_external_vpn_gateway" "gcp-external-vpn-gw" {
  name            = "gcp-external-vpn-gw"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.vpn_peer_ip
  }
}

resource "google_compute_router" "gcp-router" {
  name    = "gcp-router"
  region  = var.gcp_region
  network = google_compute_network.gcp-network.name
}

resource "google_compute_router_interface" "gcp-router-interface" {
  name       = "gcp-router-interface"
  router     = google_compute_router.gcp-router.name
  region     = var.gcp_region
  ip_range   = var.gcp_subnet1_cidr
  vpn_tunnel = google_compute_vpn_tunnel.gcp-vpn-tunnel.self_link
}

resource "google_compute_router_peer" "gcp-router-peer" {
  name                      = "gcp-router-peer"
  router                    = google_compute_router.gcp-router.name
  region                    = var.gcp_region
  peer_ip_address           = var.vpn_peer_ip
  peer_asn                  = var.vpn_peer_asn
  advertised_route_priority = 100
}

variable "gcp_region" {
  type = string
}

variable "gcp_subnet1_cidr" {
  type = string
}

variable "vpn_peer_ip" {
  type = string
}

variable "vpn_shared_secret" {
  type = string
}

variable "vpn_remote_cidr" {
  type = string
}

variable "vpn_peer_asn" {
  type = number
}