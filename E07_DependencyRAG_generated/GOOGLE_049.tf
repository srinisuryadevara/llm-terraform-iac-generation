variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  type = string
}

variable "vpn_gateway_name" {
  type = string
}

variable "tunnel_name" {
  type = string
}

variable "bgp_session_name" {
  type = string
}

variable "peer_ip" {
  type = string
}

variable "peer_asn" {
  type = number
}

variable "router_asn" {
  type = number
}

resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.network.name
  region        = var.region
}

resource "google_compute_address" "vpn_static_ip" {
  name = "vpn-static-ip"
}

resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = google_compute_network.network.self_link
}

resource "google_compute_forwarding_rule" "esp" {
  name        = "esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "udp_500" {
  name        = "udp-500"
  ip_protocol = "UDP"
  ports       = [500]
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "udp_4500" {
  name        = "udp-4500"
  ip_protocol = "UDP"
  ports       = [4500]
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

resource "google_compute_vpn_tunnel" "tunnel" {
  name               = var.tunnel_name
  region             = var.region
  vpn_gateway        = google_compute_vpn_gateway.vpn_gateway.id
  peer_ip            = var.peer_ip
  shared_secret      = "secret"
  ike_version        = 2
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  name            = "external-gateway"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.peer_ip
    ip_address_link = google_compute_vpn_tunnel.tunnel.self_link
  }
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = var.region
  network = google_compute_network.network.name
}

resource "google_compute_router_interface" "interface" {
  name       = "interface"
  router     = google_compute_router.router.name
  region     = var.region
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel.name
}

resource "google_compute_router_peer" "peer" {
  name                      = var.bgp_session_name
  router                    = google_compute_router.router.name
  region                    = var.region
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = var.peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface.name
}