provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "vpn_gateway_name" {
  type        = string
  description = "The name of the VPN gateway"
}

variable "vpn_tunnel_name" {
  type        = string
  description = "The name of the VPN tunnel"
}

variable "bgp_session_name" {
  type        = string
  description = "The name of the BGP session"
}

variable "network_name" {
  type        = string
  description = "The name of the network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "peer_ip" {
  type        = string
  description = "The IP address of the peer VPN gateway"
}

variable "peer_asn" {
  type        = number
  description = "The ASN of the peer VPN gateway"
}

variable "local_asn" {
  type        = number
  description = "The local ASN"
}

variable "tags" {
  type        = list(string)
  description = "The tags to apply to the resources"
}

resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  project                 = var.project_id
  tags                    = var.tags
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.network.id
  project       = var.project_id
  region        = var.region
  tags          = var.tags
}

resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = google_compute_network.network.id
  project = var.project_id
  region  = var.region
  tags    = var.tags
}

resource "google_compute_external_vpn_gateway" "external_vpn_gateway" {
  name            = "external-vpn-gateway"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.peer_ip
  }
  project = var.project_id
  tags    = var.tags
}

resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name                  = var.vpn_tunnel_name
  region                = var.region
  vpn_gateway           = google_compute_vpn_gateway.vpn_gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.external_vpn_gateway.id
  shared_secret         = var.shared_secret
  project               = var.project_id
  tags                  = var.tags
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  name        = "forwarding-rule"
  region      = var.region
  ip_protocol = "ESP"
  target      = google_compute_vpn_gateway.vpn_gateway.id
  project     = var.project_id
  tags        = var.tags
}

resource "google_compute_forwarding_rule" "forwarding_rule_udp_500" {
  name        = "forwarding-rule-udp-500"
  region      = var.region
  ip_protocol = "UDP"
  ports       = [500]
  target      = google_compute_vpn_gateway.vpn_gateway.id
  project     = var.project_id
  tags        = var.tags
}

resource "google_compute_forwarding_rule" "forwarding_rule_udp_4500" {
  name        = "forwarding-rule-udp-4500"
  region      = var.region
  ip_protocol = "UDP"
  ports       = [4500]
  target      = google_compute_vpn_gateway.vpn_gateway.id
  project     = var.project_id
  tags        = var.tags
}

resource "google_compute_router" "router" {
  name    = "router"
  network = google_compute_network.network.id
  project = var.project_id
  region  = var.region
  bgp {
    asn = var.local_asn
  }
  tags = var.tags
}

resource "google_compute_router_interface" "router_interface" {
  name       = "router-interface"
  router     = google_compute_router.router.name
  region     = var.region
  ip_range   = "169.254.0.2/30"
  project    = var.project_id
  tags       = var.tags
}

resource "google_compute_router_peer" "router_peer" {
  name                      = var.bgp_session_name
  router                    = google_compute_router.router.name
  region                    = var.region
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = var.peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_interface.name
  project                   = var.project_id
  tags                      = var.tags
}