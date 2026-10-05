terraform {
  required_version = ">= 1.7.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.19"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "oci" {
  region = var.region
}

# The Helm provider receives a short-lived OKE token from the OCI CLI. This is
# intentionally local-apply friendly: no kubeconfig, Kubernetes token, or OCI
# API key is stored in Terraform state.
provider "helm" {
  kubernetes {
    host                   = "https://${oci_containerengine_cluster.this.endpoints[0].public_endpoint}"
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "oci"
      args = [
        "ce", "cluster", "generate-token",
        "--cluster-id", oci_containerengine_cluster.this.id,
        "--region", var.region,
        "--token-version", "2.0.0",
      ]
    }
  }
}
