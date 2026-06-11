provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_backend_service" "example" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  backend {
    group = var.instance_group
  }

  health_checks = [var.health_check]
}

resource "google_compute_security_policy" "example" {
  name        = var.security_policy_name
  description = var.security_policy_description
}

resource "google_compute_security_policy_rule" "example" {
  security_policy = google_compute_security_policy.example.name
  priority        = var.priority
  action          = var.action
  preview         = var.preview
}

resource "google_compute_backend_service" "example_with_security_policy" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  security_policy {
    security_policy = google_compute_security_policy.example.self_link
  }

  backend {
    group = var.instance_group
  }

  health_checks = [var.health_check]
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "backend_service_name" {
  type        = string
}

variable "port_name" {
  type        = string
}

variable "protocol" {
  type        = string
}

variable "timeout_sec" {
  type        = number
}

variable "instance_group" {
  type        = string
}

variable "health_check" {
  type        = string
}

variable "security_policy_name" {
  type        = string
}

variable "security_policy_description" {
  type        = string
}

variable "priority" {
  type        = number
}

variable "action" {
  type        = string
}

variable "preview" {
  type        = bool
}