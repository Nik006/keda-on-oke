resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = var.keda_chart_version
  namespace        = "keda"
  create_namespace = true
  wait             = true
  timeout          = 900

  depends_on = [oci_containerengine_node_pool.this]
}

resource "helm_release" "nlb_keda_demo" {
  name             = "nlb-keda-demo"
  chart            = "${path.module}/charts/nlb-keda-demo"
  namespace        = "nlb-keda-test"
  create_namespace = true
  wait             = true
  timeout          = 900

  set {
    name  = "ociRegion"
    value = var.region
  }
  set {
    name  = "compartmentOcid"
    value = var.compartment_ocid
  }
  set {
    name  = "nlbTagValue"
    value = var.cluster_name
  }
  set {
    name  = "adapter.image"
    value = var.adapter_image
  }
  set {
    name  = "echo.image"
    value = var.echo_image
  }
  set {
    name  = "scaling.minReplicas"
    value = var.min_replicas
  }
  set {
    name  = "scaling.maxReplicas"
    value = var.max_replicas
  }
  set {
    name  = "scaling.connectionsPerReplica"
    value = var.connections_per_replica
  }

  depends_on = [helm_release.keda, oci_identity_policy.adapter]
}
