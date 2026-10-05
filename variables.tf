# Copyright (c) 2022, 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "tenancy_ocid" { type = string }
variable "compartment_ocid" { type = string }
variable "region" { type = string }
variable "availability_domain" { type = string }
variable "kubernetes_version" { type = string }
variable "node_image_ocid" { type = string }
variable "ssh_public_key" { type = string }
variable "admin_cidr" { type = string }
variable "nlb_client_cidr" { type = string }

variable "cluster_name" {
  type    = string
  default = "keda-nlb-oke"
}
variable "vcn_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
variable "control_plane_subnet_cidr" {
  type    = string
  default = "10.42.0.0/24"
}
variable "node_subnet_cidr" {
  type    = string
  default = "10.42.10.0/24"
}
variable "nlb_subnet_cidr" {
  type    = string
  default = "10.42.20.0/24"
}
variable "node_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}
variable "node_ocpus" {
  type    = number
  default = 2
}
variable "node_memory_gbs" {
  type    = number
  default = 16
}
variable "node_pool_size" {
  type    = number
  default = 2
}
variable "keda_chart_version" {
  type    = string
  default = "2.20.2"
}
variable "adapter_image" {
  type    = string
  default = "docker.io/library/python:3.12-slim"
}
variable "echo_image" {
  type    = string
  default = "docker.io/hashicorp/http-echo:1.0"
}
variable "min_replicas" {
  type    = number
  default = 1
}
variable "max_replicas" {
  type    = number
  default = 10
}
variable "connections_per_replica" {
  type    = number
  default = 50
}
