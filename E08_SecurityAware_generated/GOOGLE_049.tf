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
  description = "The region to create the resources"
}

variable "vpn_gateway_name" {
  type        = string
  description = "The name of the VPN gateway"
}

variable "network_name" {
  type        = string
  description = "The name of the network"
}

variable "bgp_asn" {
  type        = number
  description = "The BGP ASN"
}

variable "bgp_session_range" {
  type        = string
  description = "The BGP session range"
}

variable "tunnel_ike_version" {
  type        = string
  description = "The IKE version for the tunnel"
}

variable "tunnel_peer_ip" {
  type        = string
  description = "The peer IP for the tunnel"
}

variable "tunnel_shared_secret" {
  type        = string
  sensitive   = true
  description = "The shared secret for the tunnel"
}

resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  project                 = var.project_id
  description             = "Network for VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.network_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.network.id
  project       = var.project_id
  region        = var.region
  description   = "Subnetwork for VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = google_compute_network.network.id
  project = var.project_id
  region  = var.region
  description = "VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_external_vpn_gateway" "external_vpn_gateway" {
  name            = "${var.vpn_gateway_name}-external"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interfaces {
    ip_address = var.tunnel_peer_ip
  }
  project = var.project_id
  description = "External VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name                  = "${var.vpn_gateway_name}-tunnel"
  vpn_gateway           = google_compute_vpn_gateway.vpn_gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.external_vpn_gateway.id
  shared_secret         = var.tunnel_shared_secret
  ike_version           = var.tunnel_ike_version
  project               = var.project_id
  region                = var.region
  description           = "VPN tunnel"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  name        = "${var.vpn_gateway_name}-forwarding-rule"
  region      = var.region
  ip_protocol = "ESP"
  target      = google_compute_vpn_gateway.vpn_gateway.id
  project     = var.project_id
  description = "Forwarding rule for VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_router" "router" {
  name    = "${var.vpn_gateway_name}-router"
  network = google_compute_network.network.id
  project = var.project_id
  region  = var.region
  bgp {
    asn = var.bgp_asn
  }
  description = "Router for VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_router_interface" "router_interface" {
  name       = "${var.vpn_gateway_name}-router-interface"
  router     = google_compute_router.router.name
  region     = var.region
  ip_range   = var.bgp_session_range
  project    = var.project_id
  description = "Router interface for VPN gateway"
  labels = {
    environment = "prod"
  }
}

resource "google_compute_router_peer" "router_peer" {
  name                      = "${var.vpn_gateway_name}-router-peer"
  router                    = google_compute_router.router.name
  region                    = var.region
  interface                 = google_compute_router_interface.router_interface.name
  peer_ip_address           = var.tunnel_peer_ip
  peer_asn                  = var.bgp_asn
  advertised_route_priority = 100
  project                   = var.project_id
  description               = "Router peer for VPN gateway"
  labels = {
    environment = "prod"
  }
}