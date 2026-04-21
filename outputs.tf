output "vpc_name" {
  value = google_compute_network.prod_vpc.name
}

output "load_balancer_ip" {
  value = google_compute_forwarding_rule.prod_forwarding_rule.ip_address
}

output "web_server_1_ip" {
  value = google_compute_instance.prod_web_1.network_interface[0].network_ip
}

output "web_server_2_ip" {
  value = google_compute_instance.prod_web_2.network_interface[0].network_ip
}