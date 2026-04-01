terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Import state from the existing k3s-gitlabci-golang-demo terraform
# Run: terraform init
# Then: terraform import google_compute_instance.k3s_node projects/<project>/zones/<zone>/instances/k3s-node
#
# Or copy the statefile:
#   cp ../k3s-gitlabci-golang-demo/terraform/gcp/terraform.tfstate .

data "google_compute_default_service_account" "default" {}

resource "google_compute_instance" "k3s_node" {
  name         = "k3s-node"
  machine_type = "e2-small"
  zone         = var.zone

  tags = ["http-server", "https-server", "k3s"]

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      curl -sfL https://get.k3s.io | sh -
    EOT
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/pubsub",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}

resource "google_compute_firewall" "allow_http_https" {
  name        = "allow-http-https"
  network     = "default"
  description = "Allow HTTP and HTTPS traffic"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_k3s_api" {
  name        = "allow-k3s-api"
  network     = "default"
  description = "Allow k3s API access"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k3s"]
}

resource "google_compute_firewall" "allow_ssh" {
  name        = "allow-ssh"
  network     = "default"
  description = "Allow SSH"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k3s"]
}

resource "google_compute_firewall" "allow_nodeports" {
  name        = "allow-nodeports"
  network     = "default"
  description = "Allow NodePort range"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k3s"]
}
