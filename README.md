# simplon-azure-k8s-gitops

Azure infrastructure provisioned with Terraform, deployed from Git.
See [docs/CONSIGNES.md](docs/CONSIGNES.md) for the project brief.

## Mounting the corporate file share

Employees access the `documents` share over SMB with their own Microsoft Entra
ID account. There is no storage account key, no shared password, and nothing to
copy onto a workstation: access is granted by membership of the
`file-share-users` Entra ID group.

Replace `<account>` with the storage account name, which
`terraform output storage_account_name` prints.

### Windows

The device must be joined to Microsoft Entra ID. Map the share as a network
drive:

```
net use Z: \\<account>.file.core.windows.net\documents
```

No credentials are requested: Windows presents the Kerberos ticket it already
holds from the Entra ID sign-in. To make the drive persistent, add `/persistent:yes`.

### macOS

Requires Platform SSO with the Kerberos profile deployed, which Microsoft
currently ships as a limited preview.

1. In **Finder**, open the **Go** menu and choose **Connect to Server**, or press `Cmd+K`
2. Enter `smb://<account>.file.core.windows.net/documents`
3. Select **Connect**

The share mounts without prompting for credentials. From a terminal, the same
thing:

```bash
open smb://<account>.file.core.windows.net/documents
```

### Linux

Microsoft Entra Kerberos has no Linux client, so Linux uses **SMB OAuth**: the
Azure CLI token is exchanged for a Kerberos ticket, then the share is mounted
over ordinary SMB. A script does the whole sequence:

```bash
az login
scripts/mount-file-share.sh
```

```
Mounted
  Account        <account>
  Share          documents
  Mount point    /mnt/documents
  Capacity       100G total, 0 used, 100G free
  Identity       someone@example.com
  Auth           Entra ID token over SMB, no storage account key
  Role           Storage File Data SMB Share Contributor
  Ticket until   12:58:28
```

Unmount with `scripts/mount-file-share.sh --cleanup`.

Supported on Azure Linux 3.0, Ubuntu 22.04 and 24.04, RHEL 9.6+, and SLES 15
SP6+. Two limitations are worth knowing before you rely on it: the Kerberos
ticket lasts about an hour and is not renewed automatically, and the mount
cannot complete under WSL2 because the kernel there never runs the `cifs.upcall`
helper.

The mechanism, the RBAC reasoning behind it, and how to read a failed mount are
documented in the wiki: **[Mounting the file share on Linux](https://gitlab.com/WhiteMuush/simplon-azure-k8s-gitops/-/wikis/Mounting-the-file-share-on-Linux)**.

## Working on the infrastructure

Terraform is split into one directory per state under `terraform/`. Every Make
target delegates to a script in `scripts/`.

```bash
make help              # list the targets
make stacks            # list the stacks
make plan              # init, format, validate, then plan
make apply             # same, then apply
make plan STACK=<name> # target a specific stack
```

Without `STACK`, the targets pick the only stack when there is one and ask
otherwise. Credentials come from a `.env` file at the repository root, which is
git-ignored.
