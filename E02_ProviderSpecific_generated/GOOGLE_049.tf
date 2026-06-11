provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpn_network" {
  name                    = "vpn-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpn_subnetwork" {
  name          = "vpn-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpn_network.id
}

resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "vpn-gateway"
  network = google_compute_network.vpn_network.id
}

resource "google_compute_external_vpn_gateway" "external_vpn_gateway" {
  name            = "external-vpn-gateway"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.external_vpn_gateway_ip
  }
}

resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name                  = "vpn-tunnel"
  region                 = var.region
  vpn_gateway            = google_compute_vpn_gateway.vpn_gateway.id
  peer_external_gateway  = google_compute_external_vpn_gateway.external_vpn_gateway.id
  shared_secret          = var.shared_secret
  ike_version            = 2
  target_vpn_gateway     = google_compute_vpn_gateway.vpn_gateway.id
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]
}

resource "google_compute_forwarding_rule" "vpn_forwarding_rule" {
  name        = "vpn-forwarding-rule"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_address.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_address" "vpn_address" {
  name = "vpn-address"
}

resource "google_compute_router" "vpn_router" {
  name    = "vpn-router"
  network = google_compute_network.vpn_network.id
  bgp {
    asn = var.router_asn
  }
}

resource "google_compute_router_interface" "vpn_interface" {
  name       = "vpn-interface"
  router     = google_compute_router.vpn_router.name
  region     = var.region
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel.name
}

resource "google_compute_router_peer" "vpn_peer" {
  name                      = "vpn-peer"
  router                    = google_compute_router.vpn_router.name
  region                     = var.region
  peer_ip_address            = var.peer_ip_address
  peer_asn                   = var.peer_asn
  advertised_route_priority = 100
  interface                  = google_compute_router_interface.vpn_interface.name
}