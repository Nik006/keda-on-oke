# Copyright (c) 2022, 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.cluster_name}-vcn"
  dns_label      = "kedanlb"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-nat"
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-public-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-private-rt"

  route_rules {
    network_entity_id = oci_core_nat_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "control_plane" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-control-plane-sl"

  ingress_security_rules {
    protocol = "6"
    source   = var.admin_cidr
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.node_subnet_cidr
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "workers" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-workers-sl"

  # OKE control-plane and intra-cluster traffic stay inside the solution VCN.
  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr
  }

  # The NLB forwards public TCP/80 traffic to node ports and probes kube-proxy
  # on 10256. Both sources are in the NLB subnet.
  ingress_security_rules {
    protocol = "6"
    source   = var.nlb_subnet_cidr
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.nlb_subnet_cidr
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "nlb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.cluster_name}-nlb-sl"

  ingress_security_rules {
    protocol = "6"
    source   = var.nlb_client_cidr
    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "control_plane" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.control_plane_subnet_cidr
  display_name               = "${var.cluster_name}-control-plane"
  dns_label                  = "control"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.control_plane.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "workers" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.node_subnet_cidr
  display_name               = "${var.cluster_name}-workers"
  dns_label                  = "workers"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.workers.id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "nlb" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.nlb_subnet_cidr
  display_name               = "${var.cluster_name}-nlb"
  dns_label                  = "nlb"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.nlb.id]
  prohibit_public_ip_on_vnic = false
}
