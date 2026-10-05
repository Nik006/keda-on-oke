# Copyright (c) 2022, 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_identity_policy" "adapter" {
  compartment_id = var.compartment_ocid
  name           = "${var.cluster_name}-keda-metrics-adapter"
  description    = "Least-privilege OCI Monitoring access for the KEDA NLB metrics adapter."

  statements = [
    "Allow any-user to read metrics in compartment id ${var.compartment_ocid} where all {request.principal.type = 'workload', request.principal.namespace = 'nlb-keda-test', request.principal.service_account = 'oci-nlb-metrics-adapter', request.principal.cluster_id = '${oci_containerengine_cluster.this.id}'}",
    "Allow any-user to read network-load-balancers in compartment id ${var.compartment_ocid} where all {request.principal.type = 'workload', request.principal.namespace = 'nlb-keda-test', request.principal.service_account = 'oci-nlb-metrics-adapter', request.principal.cluster_id = '${oci_containerengine_cluster.this.id}'}",
  ]
}
