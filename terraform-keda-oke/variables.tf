variable "tenancy_ocid" {
  description = "OCID of the tenancy."
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment where all solution resources are created."
  type        = string
}

variable "region" {
  description = "OCI region identifier, for example us-ashburn-1."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name used by the worker node pool."
  type        = string
}

variable "cluster_name" {
  description = "Name prefix for the OKE cluster and solution resources."
  type        = string
  default     = "keda-nlb-oke"
}

variable "kubernetes_version" {
  description = "Supported OKE Kubernetes version to install."
  type        = string
}

variable "node_image_ocid" {
  description = "OKE-compatible Oracle Linux worker-node image OCID for the chosen Kubernetes version."
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key added to worker nodes for break-glass support."
  type        = string
}

variable "admin_cidr" {
  description = "Trusted CIDR allowed to reach the public OKE Kubernetes API endpoint. Use your public-IP /32."
  type        = string
}

variable "nlb_client_cidr" {
  description = "Trusted client CIDR allowed to reach the public NLB on TCP/80. Do not use 0.0.0.0/0 outside a lab."
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR for the solution VCN."
  type        = string
  default     = "10.42.0.0/16"
}

variable "control_plane_subnet_cidr" {
  description = "CIDR for the OKE public control-plane endpoint subnet."
  type        = string
  default     = "10.42.0.0/24"
}

variable "node_subnet_cidr" {
  description = "CIDR for private OKE worker nodes."
  type        = string
  default     = "10.42.10.0/24"
}

variable "nlb_subnet_cidr" {
  description = "CIDR for the public OCI Network Load Balancer."
  type        = string
  default     = "10.42.20.0/24"
}

variable "node_shape" {
  description = "Flexible compute shape for OKE worker nodes."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  description = "OCPUs per worker node."
  type        = number
  default     = 2
}

variable "node_memory_gbs" {
  description = "Memory in GB per worker node."
  type        = number
  default     = 16
}

variable "node_pool_size" {
  description = "Initial number of worker nodes."
  type        = number
  default     = 2
}

variable "keda_chart_version" {
  description = "Pinned KEDA Helm chart version."
  type        = string
  default     = "2.20.2"
}

variable "adapter_image" {
  description = "Lab adapter base image. Replace this with a pinned custom image in production."
  type        = string
  default     = "docker.io/library/python:3.12-slim"
}

variable "echo_image" {
  description = "Sample HTTP workload image used to demonstrate NLB scaling."
  type        = string
  default     = "docker.io/hashicorp/http-echo:1.0"
}

variable "min_replicas" {
  description = "Minimum echo replicas. Keep this at one for direct NLB traffic."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum echo replicas."
  type        = number
  default     = 10
}

variable "connections_per_replica" {
  description = "KEDA target: NLB NewConnections per minute per echo replica."
  type        = number
  default     = 50
}
