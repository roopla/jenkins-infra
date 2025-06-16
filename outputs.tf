output "jenkins-ips" {
  value = {
    for instance in google_compute_instance.jenkins_instances :
    instance.name => instance.network_interface[0].access_config[0].nat_ip
  }
  
} 
  


