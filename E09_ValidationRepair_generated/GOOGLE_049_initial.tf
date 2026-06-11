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
  name                  = var.vpn_tunnel_name
  region                = var.region
  vpn_gateway           = google_compute_vpn_gateway.vpn_gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.external_vpn_gateway.id
  shared_secret         = var.vpn_shared_secret
  ike_version           = 2
}

resource "google_compute_forwarding_rule" "vpn_forwarding_rule" {
  name        = var.vpn_forwarding_rule_name
  region      = var.region
  ip_protocol = "ESP"
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "vpn_forwarding_rule_esp" {
  name        = var.vpn_forwarding_rule_esp_name
  region      = var.region
  ip_protocol = "UDP"
  ports       = [500, 4500]
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_router" "vpn_router" {
  name    = var.vpn_router_name
  region  = var.region
  network = google_compute_network.vpn_network.id
}

resource "google_compute_router_interface" "vpn_router_interface" {
  name       = var.vpn_router_interface_name
  router     = google_compute_router.vpn_router.name
  region     = var.region
  ip_range   = var.vpn_router_interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel.name
}

resource "google_compute_router_bgp_peer" "vpn_bgp_peer" {
  name                      = var.vpn_bgp_peer_name
  router                    = google_compute_router.vpn_router.name
  region                    = var.region
  peer_ip_address           = var.vpn_bgp_peer_ip
  peer_asn                  = var.vpn_bgp_peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.vpn_router_interface.name
}