# Copyright (c) 2022, 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "cluster_id" {
  value = module.keda_on_oke.cluster_id
}

output "cluster_name" {
  value = module.keda_on_oke.cluster_name
}

output "kubernetes_api_endpoint" {
  value = module.keda_on_oke.kubernetes_api_endpoint
}

output "nlb_public_ip" {
  value = module.keda_on_oke.nlb_public_ip
}

output "validation_commands" {
  value = module.keda_on_oke.validation_commands
}
