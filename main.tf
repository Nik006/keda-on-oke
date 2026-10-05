# Copyright (c) 2022, 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Resource Manager starts Terraform at the root of the downloaded GitHub ZIP.
# This wrapper keeps the implementation in terraform-keda-oke while making the
# repository directly deployable through a Resource Manager quick-create URL.
module "keda_on_oke" {
  source = "./terraform-keda-oke"

  tenancy_ocid              = var.tenancy_ocid
  compartment_ocid          = var.compartment_ocid
  region                    = var.region
  availability_domain       = var.availability_domain
  cluster_name              = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  node_image_ocid           = var.node_image_ocid
  ssh_public_key            = var.ssh_public_key
  admin_cidr                = var.admin_cidr
  nlb_client_cidr           = var.nlb_client_cidr
  vcn_cidr                  = var.vcn_cidr
  control_plane_subnet_cidr = var.control_plane_subnet_cidr
  node_subnet_cidr          = var.node_subnet_cidr
  nlb_subnet_cidr           = var.nlb_subnet_cidr
  node_shape                = var.node_shape
  node_ocpus                = var.node_ocpus
  node_memory_gbs           = var.node_memory_gbs
  node_pool_size            = var.node_pool_size
  keda_chart_version        = var.keda_chart_version
  adapter_image             = var.adapter_image
  echo_image                = var.echo_image
  min_replicas              = var.min_replicas
  max_replicas              = var.max_replicas
  connections_per_replica   = var.connections_per_replica
}
