# Terraform Repository Blueprint: KEDA on OKE

Use this layout for the GitHub repository linked from the Solution Hub article:

```text
keda-on-oci/
├── README.md
├── versions.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── networking.tf
├── oke.tf
├── addons.tf
├── keda.tf
├── demo.tf
├── terraform.tfvars.example
├── manifests/
│   ├── namespace.yaml
│   ├── rabbitmq.yaml
│   ├── worker.yaml
│   ├── trigger-authentication.yaml.tftpl
│   └── scaledobject.yaml
└── .github/workflows/terraform.yml
```

## Terraform responsibilities

- `networking.tf`: private OKE worker subnet, public API endpoint only if the intended access model requires it, NAT/service gateways, and least-privilege security rules.
- `oke.tf`: OKE cluster and a managed node pool. Expose node-pool size, shape, and autoscaler bounds as variables.
- `addons.tf`: install Metrics Server and, when enabled, the OKE Cluster Autoscaler using OCI-supported OKE add-on configuration.
- `keda.tf`: configure the Helm and Kubernetes providers from the created OKE cluster; install the pinned KEDA Helm chart into a `keda` namespace.
- `demo.tf`: apply the manifest files only when `deploy_demo = true`; do not make the RabbitMQ demonstration a production dependency.
- `outputs.tf`: cluster OCID, node-pool OCID, kubeconfig command, and a post-deploy validation command. Do not output secret values.

## Inputs to expose

Required inputs: `tenancy_ocid`, `compartment_ocid`, `region`, `availability_domain`, `ssh_public_key`, and a validated network CIDR. Sensible optional inputs include `kubernetes_version`, node shape, node pool minimum/maximum size, `keda_chart_version`, `deploy_demo`, and worker minimum/maximum replicas.

Use OCI Resource Manager only after the local Terraform workflow is repeatable. For a genuine “single-click” experience, package the exact same code as a Resource Manager stack, provide a schema for variables, and make the Terraform plan visible before apply.

## Acceptance checks

1. `terraform validate` and `terraform plan` complete without secrets in output.
2. KEDA operator, metrics API server, and admission webhook are ready in the `keda` namespace.
3. A `ScaledObject` creates its expected HPA in the demo namespace.
4. Adding messages activates the worker from zero and increases replicas within the configured bounds.
5. Draining the queue returns the worker to zero after the cooldown.
6. When demand cannot fit on current nodes, the OKE Cluster Autoscaler grows the configured node pool; it shrinks again only when pods can be safely rescheduled.

## Design decision to make before coding

Pick the production event source first. RabbitMQ is an excellent demonstration because KEDA has a native scaler, but it should not dictate the production architecture. If the target is OCI Streaming, plan an OCI Streaming metric exporter and KEDA Prometheus scaler (or an external scaler) as a separately tested component. That keeps the Terraform stack broadly useful and makes the event-source integration explicit.
