# Copyright (c) 2022, 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_ocid
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vcn_id             = oci_core_vcn.this.id
  type               = "ENHANCED_CLUSTER"

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.control_plane.id
  }

  options {
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }

    service_lb_config {
      freeform_tags = {
        Solution = "keda-nlb-autoscaling"
      }
    }

    service_lb_subnet_ids = [oci_core_subnet.nlb.id]
  }
}

resource "oci_containerengine_node_pool" "this" {
  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_ocid
  name               = "${var.cluster_name}-workers"
  kubernetes_version = var.kubernetes_version
  node_shape         = var.node_shape
  ssh_public_key     = var.ssh_public_key

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gbs
  }

  node_source_details {
    image_id    = var.node_image_ocid
    source_type = "IMAGE"
  }

  node_config_details {
    size = var.node_pool_size

    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = oci_core_subnet.workers.id
    }
  }
}

data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id    = oci_containerengine_cluster.this.id
  token_version = "2.0.0"
  depends_on    = [oci_containerengine_node_pool.this]
}

locals {
  kubeconfig = yamldecode(data.oci_containerengine_cluster_kube_config.this.content)
}
