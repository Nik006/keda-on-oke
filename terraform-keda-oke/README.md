# One-click KEDA scaling from OCI Network Load Balancer metrics

This Terraform root module builds an isolated OCI environment and deploys an end-to-end KEDA demonstration in one `terraform apply`:

```text
Internet client
  -> public OCI Network Load Balancer
  -> echo Deployment on private OKE workers
  -> OCI Monitoring (oci_nlb.NewConnections)
  -> in-cluster OCI metrics adapter
  -> KEDA Metrics API scaler
  -> KEDA-managed HPA scales echo from 1 to N replicas
```

## What it creates

- VCN, Internet Gateway, NAT Gateway, public control-plane/NLB subnets, and a private worker subnet.
- Security lists that expose TCP/80 only to `nlb_client_cidr`; worker nodes remain private.
- Enhanced OKE cluster with VCN-native pod networking and one configurable worker node pool.
- A least-privilege OKE Workload Identity policy. Only the `oci-nlb-metrics-adapter` ServiceAccount in the `nlb-keda-test` namespace can read OCI Monitoring metrics and NLB metadata.
- KEDA `2.20.2`, installed from its official Helm chart.
- A public `echo-nlb` Service, OCI NLB metrics adapter, and `ScaledObject` that targets the echo Deployment.

The adapter discovers the NLB by its `keda-solution=nlb-keda-demo` freeform tag, then queries `oci_nlb.NewConnections` through the OCI Monitoring `SummarizeMetricsData` API. It exposes:

```json
{"nlb":{"newConnectionsPerMinute":251}}
```

KEDA’s generated HPA targets 50 new connections per minute per replica by default.

## Prerequisites

Run this **locally** from a trusted machine. The Helm provider invokes the OCI CLI to obtain short-lived OKE tokens, so OCI Resource Manager is not the target execution environment for this root module.

- Terraform `>= 1.7`
- OCI CLI authenticated as a principal that can create VCN, OKE, Compute, IAM policy, and network resources in the chosen compartment
- Helm `>= 3` and an OCI CLI version that supports `oci ce cluster generate-token --token-version 2.0.0`
- Access from your `admin_cidr` to the OKE API endpoint
- A current, OKE-compatible worker image OCID for the selected Kubernetes version

The principal applying this module also requires cluster-admin authorization in the new OKE cluster, because the Helm provider installs KEDA and the demo chart.

## Deploy

```bash
cd terraform-keda-oke
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars. Never commit it.
terraform init
terraform plan
terraform apply
```

Use a `/32` value for `admin_cidr` and `nlb_client_cidr` whenever possible. The example addresses are documentation-only and cannot be used as-is.

After apply, create a kubeconfig using the printed `cluster_id`, then obtain the NLB address:

```bash
oci ce cluster create-kubeconfig \
  --cluster-id <cluster-id> \
  --file ./kubeconfig \
  --region <region> \
  --token-version 2.0.0

export KUBECONFIG=$PWD/kubeconfig
kubectl get service echo-nlb -n nlb-keda-test
kubectl get scaledobject,hpa,deployment -n nlb-keda-test
```

## Verify scaling

Confirm the adapter and KEDA signal path:

```bash
kubectl exec -n nlb-keda-test deploy/oci-nlb-metrics-adapter -- \
  python -c 'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8080/metrics/nlb").read().decode())'

kubectl describe hpa keda-hpa-echo-nlb-traffic -n nlb-keda-test
```

Run a controlled test from an IP allowed by `nlb_client_cidr`:

```bash
ab -n 5000 -c 10 http://<public-nlb-ip>/
```

OCI Monitoring publishes service metrics on a roughly one-minute cadence. Once `NewConnections` exceeds the target, the HPA will show an external metric named similar to `s0-metric-api-nlb-newConnectionsPerMinute` and increase the echo replicas. KEDA creates and owns that HPA; do not create a second HPA for `echo`.

## Production hardening

This demonstration intentionally installs the OCI Python SDK at adapter startup to keep the source self-contained. Before production, build and pin an adapter image in OCIR or another approved registry, remove runtime package installation, add NetworkPolicies, and send adapter/KEDA logs and metrics to your observability platform.

NLB `NewConnections` is appropriate for gradual **1-to-N** scaling. Keep `min_replicas` at one for a direct NLB-served service; NLB traffic cannot wake a workload with no healthy backends. For scale-to-zero HTTP workloads, use a dedicated request-activation layer instead.

Use supported combinations of KEDA and OKE Kubernetes versions. The KEDA operator logs a warning when it runs against an untested Kubernetes version.

## Destroy

```bash
terraform destroy
```

The command removes the cluster, NLB, IAM policy, and VCN resources created by this module. Review the destroy plan carefully; do not point this module at a shared VCN or production compartment.
