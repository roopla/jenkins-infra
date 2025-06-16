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


# Create a ssh keypair, combination of public and private key
resource "tls_private_key" "ssh-key-pair" {
  algorithm = "RSA"
  rsa_bits = "4096"
}

# Save the private key to local file 
resource "local_file" "ssh-key-private" {
  content = tls_private_key.ssh-key-pair.private_key_pem
  filename = "${path.module}/id_rsa"
}

# Save the Public key to local file 
resource "local_file" "ssh-key-public" {
  content = tls_private_key.ssh-key-pair.public_key_openssh
  filename = "${path.module}/id_rsa.pub"
}

locals {
  instances = {
    jenkins-master = {
      tags = ["jenkins-master"]
      script = "${path.module}/jenkins-master.sh"
    }
    jenkins-slave = {
      tags = ["jenkins-slave"]
      script = "${path.module}/jenkins-slave.sh"
    }
  }
}


resource "google_compute_instance" "jenkins_instances" {
  for_each = local.instances

  name         = each.key
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = each.value.tags

  connection {    
    type        = "ssh"
    user        = var.vm_user
    private_key = tls_private_key.ssh-key-pair.private_key_pem
    host        = self.network_interface[0].access_config[0].nat_ip       
    
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${tls_private_key.ssh-key-pair.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250606"
    }
  }

  network_interface {
    network    = google_compute_network.jenkins_net.name
    subnetwork = google_compute_subnetwork.jenkins_subnet.name
    access_config {}
  }



 provisioner "remote-exec" {
  when    = "create"
  inline = [
    "sudo mkdir -p /home/${var.vm_user}/jenkins",
    "sudo chown -R ${var.vm_user}:${var.vm_user} /home/${var.vm_user}/jenkins"
  ]
}

  metadata_startup_script = file(each.value.script)


}