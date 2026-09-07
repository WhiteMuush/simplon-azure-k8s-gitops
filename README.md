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

## Usage

```bash
make help              # list the targets
make stacks            # list the stacks
make plan              # init, format, validate, then plan
make apply             # same, then apply
make plan STACK=<name> # target a specific stack
```

Credentials come from a `.env` file at the repository root, which is git-ignored.

## Layout

```
terraform/    one directory per Terraform state
manifests/    Kubernetes manifests, applied to the cluster
make/         one .mk file per domain, included by the Makefile
scripts/      every Makefile target delegates here, grouped by domain
docs/         the project brief
```
