# Deploy KEDA on OKE using OCI NLB metrics

This repository deploys an end-to-end KEDA demonstration on Oracle Kubernetes Engine (OKE). It provisions a new OKE environment, exposes a sample HTTP application through an OCI Network Load Balancer (NLB), reads the NLB `NewConnections` metric from OCI Monitoring, and scales the application through KEDA.

```text
Client traffic
  -> OCI Network Load Balancer
  -> echo application on OKE
  -> OCI Monitoring: oci_nlb.NewConnections
  -> internal OCI metrics adapter
  -> KEDA Metrics API scaler
  -> KEDA-managed HPA
  -> echo replicas: 1 to N
```

## What is deployed

- VCN, Internet Gateway, NAT Gateway, routing, and security lists
- Enhanced OKE cluster with private worker nodes
- Public OCI Network Load Balancer for the sample application
- KEDA Helm chart
- OCI Monitoring adapter using OKE Workload Identity
- Least-privilege IAM policy for the adapter
- `ScaledObject` that scales the sample application from 1 to 10 replicas

The default scaling target is 50 new NLB connections per minute per application replica.

## Prerequisites

Run Terraform from your local workstation. This solution uses the OCI CLI to obtain short-lived OKE tokens for the Helm provider.

- Terraform 1.7 or later
- OCI CLI authenticated to the target tenancy
- Helm 3 or later
- OCI permissions to create networking, OKE, Compute, and IAM policy resources
- An OKE-compatible worker image OCID for your selected Kubernetes version
- A public SSH key for worker-node access
- Your public IP address in CIDR form, such as `203.0.113.10/32`

Do not run this Terraform root module from OCI Resource Manager without adapting the OKE authentication method.

## Configure the deployment

```bash
cd terraform-keda-oke
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set these values:

| Variable | Description |
| --- | --- |
| `tenancy_ocid` | OCI tenancy OCID |
| `compartment_ocid` | Compartment where the solution is created |
| `region` | OCI region, for example `us-ashburn-1` |
| `availability_domain` | Worker-node availability domain |
| `kubernetes_version` | Supported OKE Kubernetes version |
| `node_image_ocid` | OKE-compatible worker image OCID |
| `ssh_public_key` | SSH public key for worker nodes |
| `admin_cidr` | Trusted CIDR allowed to access the OKE API |
| `nlb_client_cidr` | Trusted CIDR allowed to access NLB TCP/80 |

Use `/32` CIDRs whenever possible. Do not use `0.0.0.0/0` outside a short-lived lab environment.

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

Review the plan carefully before confirming. The deployment creates billable OCI resources, including worker nodes and a public NLB.

## Connect to the cluster

After Terraform completes, create a kubeconfig:

```bash
oci ce cluster create-kubeconfig \
  --cluster-id "$(terraform output -raw cluster_id)" \
  --file ./kubeconfig \
  --region <your-region> \
  --token-version 2.0.0

export KUBECONFIG=$PWD/kubeconfig
```

Check the deployed components:

```bash
kubectl get pods -n keda
kubectl get pods -n nlb-keda-test
kubectl get scaledobject,hpa,deployment -n nlb-keda-test
kubectl get service echo-nlb -n nlb-keda-test
```

The `echo-nlb` Service output includes the public NLB address.

## Verify the OCI metrics adapter

The adapter should return the latest OCI NLB `NewConnections` metric:

```bash
kubectl exec -n nlb-keda-test deploy/oci-nlb-metrics-adapter -- \
  python -c 'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8080/metrics/nlb").read().decode())'
```

Expected response:

```json
{"nlb":{"newConnectionsPerMinute":36.0}}
```

The number varies based on NLB traffic.

## Verify KEDA scaling

Generate traffic from a client IP allowed by `nlb_client_cidr`:

```bash
ab -n 5000 -c 10 http://<public-nlb-ip>/
```

Watch KEDA and the HPA:

```bash
kubectl get scaledobject,hpa,deployment -n nlb-keda-test --watch
```

When the NLB metric rises above the configured target, the HPA displays an external metric similar to this:

```text
s0-metric-api-nlb-newConnectionsPerMinute: 251 / 50
```

The HPA then increases the `echo` deployment replica count. KEDA owns this HPA; do not create another HPA for the same Deployment.

OCI service metrics usually arrive on a one-minute cadence, so allow one to two minutes before expecting the replica count to change.

## Troubleshooting

```bash
# KEDA controller logs
kubectl logs -n keda deploy/keda-operator --tail=100

# Scaler and HPA state
kubectl describe scaledobject echo-nlb-traffic -n nlb-keda-test
kubectl describe hpa keda-hpa-echo-nlb-traffic -n nlb-keda-test

# Namespace events
kubectl get events -n nlb-keda-test --sort-by=.lastTimestamp
```

If the NLB is not reachable, confirm that `nlb_client_cidr` allows your client IP and that worker-node security rules allow NLB health checks and NodePort traffic.

## Clean up

```bash
terraform destroy
```

Review the destroy plan before confirming. It removes the resources created by this Terraform module, including the OKE cluster, NLB, IAM policy, and VCN.

## Production notes

- Replace the adapter's runtime `pip install` with a pinned custom image from OCIR or another approved registry.
- Use OCI Vault or an external secrets solution for any future credentials.
- Send KEDA, adapter, application, and NLB metrics to your observability platform.
- Keep `min_replicas = 1` for an application reached directly through an NLB. A direct NLB cannot send the first request to a workload with zero healthy backends.
- Validate your selected KEDA and Kubernetes versions against the current support matrix before production use.

For Terraform implementation details, see [terraform-keda-oke/README.md](terraform-keda-oke/README.md).
