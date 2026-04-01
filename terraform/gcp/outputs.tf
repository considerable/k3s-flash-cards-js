output "external_ip" {
  description = "Public IP of k3s node"
  value       = google_compute_instance.k3s_node.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Internal IP of k3s node"
  value       = google_compute_instance.k3s_node.network_interface[0].network_ip
}

output "ssh_command" {
  description = "SSH into the k3s node"
  value       = "gcloud compute ssh k3s-node --zone=${var.zone}"
}

output "kubeconfig_command" {
  description = "Get kubeconfig from k3s node"
  value       = "gcloud compute ssh k3s-node --zone=${var.zone} --command='sudo cat /etc/rancher/k3s/k3s.yaml'"
}

output "deploy_flash_cards" {
  description = "Deploy flash-cards-js app via Helm"
  value       = "helm upgrade --install flash-cards-js ./helm/flash-cards-js -f ./helm/flash-cards-js/values-gcp.yaml"
}
