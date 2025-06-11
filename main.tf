provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}


resource "google_compute_network" "jenkins_net" {
  name                    = "jenkins-network"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "jenkins_subnet" {
  name          = "jenkins-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.jenkins_net.id
}


resource "google_compute_firewall" "jenkins_firewall" {
  name    = "jenkins-allow-ssh-http"
  network = google_compute_network.jenkins_net.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins-master", "jenkins-slave"]
}


resource "google_compute_instance" "jenkins_master" {
  name         = "jenkins-master"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250606"
    }
  }

  network_interface {
    network    = google_compute_network.jenkins_net.id
    subnetwork = google_compute_subnetwork.jenkins_subnet.id
    access_config {}
  }

  metadata_startup_script = file("${path.module}/jenkins-master.sh")
  tags                    = ["jenkins-master"]
}


resource "google_compute_instance" "terraform_slave" {
  name         = "terraform-slave"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250606"
    }
  }

  network_interface {
    network    = google_compute_network.jenkins_net.id
    subnetwork = google_compute_subnetwork.jenkins_subnet.id
    access_config {}
  }

  metadata_startup_script = file("${path.module}/terraform-slave.sh")
  tags                    = ["jenkins-slave"]
}
