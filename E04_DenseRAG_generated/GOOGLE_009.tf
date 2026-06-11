# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a network
resource "google_compute_network" "vpn_network" {
  name                    = "vpn-network"
  auto_create_subnetworks = "false"
}

# Create a subnet
resource "google_compute_subnetwork" "vpn_subnet" {
  name          = "vpn-subnet"
  ip_cidr_range = var.vpn_subnet_cidr
  network       = google_compute_network.vpn_network.name
  region        = var.region
}

# Create a VPN gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "vpn-gateway"
  network = google_compute_network.vpn_network.self_link
  region  = var.region
}

# Create a VPN tunnel
resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name                  = "vpn-tunnel"
  region                = var.region
  vpn_gateway           = google_compute_vpn_gateway.vpn_gateway.self_link
  peer_ip               = var.vpn_peer_ip
  shared_secret         = var.vpn_shared_secret
  ike_version           = 2
  local_traffic_selector = [var.vpn_local_traffic_selector]
  remote_traffic_selector = [var.vpn_remote_traffic_selector]
}

# Create a forwarding rule for ESP
resource "google_compute_forwarding_rule" "esp_forwarding_rule" {
  name        = "esp-forwarding-rule"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

# Create a forwarding rule for UDP 500
resource "google_compute_forwarding_rule" "udp_500_forwarding_rule" {
  name        = "udp-500-forwarding-rule"
  ip_protocol = "UDP"
  ports       = [500]
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

# Create a forwarding rule for UDP 4500
resource "google_compute_forwarding_rule" "udp_4500_forwarding_rule" {
  name        = "udp-4500-forwarding-rule"
  ip_protocol = "UDP"
  ports       = [4500]
  ip_address  = google_compute_address.vpn_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
}

# Create a BGP session
resource "google_compute_router" "vpn_router" {
  name    = "vpn-router"
  region  = var.region
  network = google_compute_network.vpn_network.name
}

resource "google_compute_router_bgp_peer" "vpn_bgp_peer" {
  name                      = "vpn-bgp-peer"
  router                    = google_compute_router.vpn_router.name
  peer_ip_address           = var.vpn_peer_ip
  peer_asn                  = var.vpn_peer_asn
  advertised_route_priority = 100
}

# Create a VPN IP address
resource "google_compute_address" "vpn_ip" {
  name   = "vpn-ip"
  region = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpn_subnet_cidr" {
  type = string
}

variable "vpn_peer_ip" {
  type = string
}

variable "vpn_shared_secret" {
  type = string
}

variable "vpn_local_traffic_selector" {
  type = string
}

variable "vpn_remote_traffic_selector" {
  type = string
}

variable "vpn_peer_asn" {
  type = number
}