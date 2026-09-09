# simplon-azure-k8s-gitops

Azure infrastructure provisioned with Terraform, deployed from Git.

## Documentation

- [Project brief](docs/CONSIGNES.md)
- [Wiki](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/home), for architecture decisions and operating procedures

## Mounting the file share

Employees mount the `documents` share with their own Microsoft Entra ID account.
Each system authenticates differently:

- [Windows](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-Windows)
- [macOS](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-macOS)
- [Linux](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-Linux)

## Backing up the cluster

Velero backs the `demo` namespace up to a blob container every night, with no
credential stored in the cluster. See
[Backing up the cluster](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Backing-up-the-cluster).

## Usage

```bash
make help              # every target, grouped by domain

make plan              # init, format, validate, then plan
make apply             # same, then apply
make apply STACK=<name># target a specific stack
make status            # what is deployed, per stack and in Azure

make kubeconfig        # cluster access through Entra ID
make wake              # bring the nodes back once they are deallocated
make db-secret         # generate the database password in the Key Vault
make db-wire           # write the database identity into the manifests
make db-shell          # psql session on the database pod
make argocd-ui         # port-forward the Argo CD UI and print the login
make velero-install    # Velero and the daily schedule
make velero-restore    # delete the demo namespace and restore it
```

Credentials come from a `.env` file at the repository root, which is git-ignored.

## Deploying from the pipeline

The same scripts run in GitLab CI on `main`, so nothing has to be installed from
a workstation:

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
