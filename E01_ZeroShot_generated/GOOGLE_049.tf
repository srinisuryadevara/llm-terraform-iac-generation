provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpn_network" {
  name                    = var.vpn_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpn_subnetwork" {
  name          = var.vpn_subnetwork_name
  ip_cidr_range = var.vpn_subnetwork_cidr
  network       = google_compute_network.vpn_network.id
  region        = var.region
}

resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = google_compute_network.vpn_network.id
}

resource "google_compute_external_vpn_gateway" "external_vpn_gateway" {
  name            = var.external_vpn_gateway_name
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.external_vpn_gateway_ip
  }
}

resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name               = var.vpn_tunnel_name
  region              = var.region
  vpn_gateway         = google_compute_vpn_gateway.vpn_gateway.id
  peer_ip            = var.external_vpn_gateway_ip
  shared_secret      = var.vpn_shared_secret
  ike_version        = 2
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "vpn_forwarding_rule" {
  name        = var.vpn_forwarding_rule_name
  region      = var.region
  ip_protocol = "ESP"
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "vpn_forwarding_rule_esp" {
  name        = "${var.vpn_forwarding_rule_name}-esp"
  region      = var.region
  ip_protocol = "UDP"
  ports       = [500, 4500]
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_router" "vpn_router" {
  name    = var.vpn_router_name
  network = google_compute_network.vpn_network.id
  region  = var.region
}

resource "google_compute_router_interface" "vpn_router_interface" {
  name       = var.vpn_router_interface_name
  router     = google_compute_router.vpn_router.id
  ip_range   = var.vpn_router_interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel.id
}

resource "google_compute_router_peer" "vpn_router_peer" {
  name                      = var.vpn_router_peer_name
  router                     = google_compute_router.vpn_router.id
  peer_ip_address            = var.vpn_router_peer_ip
  peer_asn                   = var.vpn_router_peer_asn
  advertised_route_priority  = 100
  interface                  = google_compute_router_interface.vpn_router_interface.name
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpn_network_name" {
  type = string
}

variable "vpn_subnetwork_name" {
  type = string
}

variable "vpn_subnetwork_cidr" {
  type = string
}

variable "vpn_gateway_name" {
  type = string
}

variable "external_vpn_gateway_name" {
  type = string
}

variable "external_vpn_gateway_ip" {
  type = string
}

variable "vpn_tunnel_name" {
  type = string
}

variable "vpn_shared_secret" {
  type = string
}

variable "vpn_forwarding_rule_name" {
  type = string
}

variable "vpn_router_name" {
  type = string
}

variable "vpn_router_interface_name" {
  type = string
}

variable "vpn_router_interface_ip_range" {
  type = string
}

variable "vpn_router_peer_name" {
  type = string
}

variable "vpn_router_peer_ip" {
  type = string
}

variable "vpn_router_peer_asn" {
  type = number
}