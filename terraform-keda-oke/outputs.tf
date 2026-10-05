output "cluster_id" {
  value = oci_containerengine_cluster.this.id
}

output "cluster_name" {
  value = oci_containerengine_cluster.this.name
}

output "kubernetes_api_endpoint" {
  value = oci_containerengine_cluster.this.endpoints[0].public_endpoint
}

output "nlb_public_ip" {
  description = "Retrieve after apply with: kubectl get service echo-nlb -n nlb-keda-test."
  value       = "kubectl get service echo-nlb -n nlb-keda-test"
}

output "validation_commands" {
  value = <<-EOT
    kubectl get scaledobject,hpa,deployment -n nlb-keda-test
    kubectl describe hpa keda-hpa-echo-nlb-traffic -n nlb-keda-test
  EOT
}
