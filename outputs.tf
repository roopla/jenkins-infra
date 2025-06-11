output "jenkins_master_ip" {
  value = google_compute_instance.jenkins_master.network_interface[0].access_config[0].nat_ip
}

output "terraform_slave_ip" {
  value = google_compute_instance.terraform_slave.network_interface[0].access_config[0].nat_ip
}

output "jenkins_url" {
  value       = "http://${google_compute_instance.jenkins_master.network_interface[0].access_config[0].nat_ip}:8080"
  
}

