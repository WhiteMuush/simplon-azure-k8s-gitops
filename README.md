# simplon-azure-k8s-gitops

Azure infrastructure provisioned with Terraform, deployed from Git: an AKS
cluster running PostgreSQL, an SMB file share for employees, and nightly
backups to blob storage. No credential is stored in Git or in the cluster.

## Documentation

- [Infrastructure overview](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Infrastructure-overview), what the stacks own and what deploys what
- [Project brief](docs/CONSIGNES.md)
- [Wiki](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/home), for architecture decisions and operating procedures

## Mounting the file share

Employees mount the `documents` share with their own Microsoft Entra ID account.
Each system authenticates differently:

- [Windows](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-Windows)
- [macOS](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-macOS)
- [Linux](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-Linux)

## Backing up the cluster

Velero backs the `demo` and `database` namespaces up to a blob container every
night, with no credential stored in the cluster. See
[Backing up the cluster](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Backing-up-the-cluster).

## Requirements

`terraform`, `az`, `kubectl`, `helm`, `make`. Sign in with `az login`, then copy
`.env.example` to `.env` and fill it in. It is git-ignored and every script
sources it.

## Usage

`make help` lists every target. The ones worth knowing:

```bash
make apply STACK=<name>  # init, format, validate, then apply one stack
make status              # what is deployed, per stack and in Azure
make kubeconfig          # cluster access through Entra ID
make db-shell            # psql session on the database pod
make argocd-ui           # port-forward the Argo CD UI and print the login
make velero-restore      # delete the demo namespace and restore it
```

Stacks read each other through `terraform_remote_state`, so the order is not
free: `cicd`, then `identity`, then `storage`, then `kubernetes`. Applying out
of order fails on an output that does not exist yet.

## Deploying from the pipeline

The same scripts run in GitLab CI on `main`, so the platform needs no
workstation. Only `cicd` and `identity` are applied by hand: they need
directory rights the pipeline does not have.

| Job | What it does |
| --- | --- |
| `outputs` | reads the cluster name and the Velero identity from the Terraform state |
| `deploy:argocd` | `helm upgrade --install` of Argo CD, then applies the root application |
| `deploy:velero` | `helm upgrade --install` of Velero, then applies the backup schedule |

Both deploy jobs are manual. They authenticate with the same OIDC token as
Terraform: `az login --federated-token`, then `kubelogin` converts the kubeconfig,
because the cluster has local accounts disabled. The pipeline service principal
holds `Azure Kubernetes Service Cluster User Role` and
`Azure Kubernetes Service RBAC Cluster Admin`, scoped to the cluster only.

## Layout

```
terraform/    one directory per Terraform state
manifests/    Kubernetes manifests, applied to the cluster
make/         one .mk file per domain, included by the Makefile
scripts/      every Makefile target delegates here, grouped by domain
docs/         the project brief
```
