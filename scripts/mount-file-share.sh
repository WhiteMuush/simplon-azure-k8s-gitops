#!/usr/bin/env bash
# Mount the Azure file share on Linux with the employee's own Entra ID token,
# over real SMB, with no storage account key.
#
# The point of the experiment: check whether the plain "Storage File Data SMB
# Share Contributor" role is enough. Microsoft documents this path for VMs and
# applications and tells you to assign "Storage File Data SMB MI Admin", which
# bypasses NTFS permissions. If the plain role works, Linux gets a
# credential-free mount with NTFS still enforced.
#
# Usage:
#   scripts/mount-file-share.sh --enable    turn on SMB OAuth, then mount
#   scripts/mount-file-share.sh             mount
#   scripts/mount-file-share.sh --diagnose  inspect the whole chain
#   scripts/mount-file-share.sh --debug     retry with CIFS verbose logging
#   scripts/mount-file-share.sh --cleanup   unmount and drop the cached credential

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-mpfilesprod2026}"
SHARE_NAME="${SHARE_NAME:-documents}"
RESOURCE_GROUP="${RESOURCE_GROUP:-mpetitRG}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/${SHARE_NAME}}"
ENDPOINT="https://${STORAGE_ACCOUNT}.file.core.windows.net"
UNC_PATH="//${STORAGE_ACCOUNT}.file.core.windows.net/${SHARE_NAME}"
CONFIG_FILE="/etc/azfilesauth/config.yaml"
KRB5_CONF="/etc/krb5.conf"
KERBEROS_REALM="FILES.AZURE.STORAGE.MICROSOFT.COM"
TOKEN_AUDIENCE="https://storage.azure.com"
MOUNT_OPTIONS="dir_mode=0755,file_mode=0755,serverino,nosharesock,mfsymlinks,actimeo=30"

# Set by the steps below, read by the ones after.
OS_VERSION_ID=""
ACCESS_TOKEN=""
CRED_UID=""

# ---------------------------------------------------------------- output ----

step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
field() { printf '  %-14s %s\n' "$1" "$2"; }

# ------------------------------------------------------------- preflight ----

check_supported_os() {
  # shellcheck source=/dev/null
  source /etc/os-release
  OS_VERSION_ID="$VERSION_ID"
  case "${ID}:${VERSION_ID}" in
    ubuntu:22.04 | ubuntu:24.04 | rhel:9.* | sles:15* | azurelinux:3.0)
      ok "$PRETTY_NAME"
      ;;
    *)
      die "${PRETTY_NAME} is not in the azfilesauth support list."
      ;;
  esac
}

# az account show only reads the local cache, so it succeeds long after the
# refresh token died. Force a real token request instead.
check_azure_session() {
  command -v az >/dev/null || die "The Azure CLI is missing."
  az account show >/dev/null 2>&1 || die "Not signed in. Run: az login"
  local tenant
  tenant="$(az account show --query tenantId -o tsv 2>/dev/null || echo "")"
  az account get-access-token --output none 2>/dev/null ||
    die "The session expired. Run: az login --tenant ${tenant}"
  ok "signed in as $(az account show --query user.name -o tsv)"
}

verify_smb_oauth() {
  local state
  state="$(query_smb_oauth_state)"
  case "$state" in
    true | True) ok "SMB OAuth enabled on ${STORAGE_ACCOUNT}" ;;
    unknown) warn "this az version cannot read the SMB OAuth property" ;;
    *) die "SMB OAuth is off on ${STORAGE_ACCOUNT}. Rerun with --enable." ;;
  esac
}

query_smb_oauth_state() {
  az storage account show \
    --resource-group "$RESOURCE_GROUP" --name "$STORAGE_ACCOUNT" \
    --query "azureFilesIdentityBasedAuthentication.smbOAuthSettings.isSmbOAuthEnabled" \
    -o tsv 2>/dev/null || echo "unknown"
}

enable_smb_oauth() {
  # The azurerm provider 5.4.0 has no attribute for this yet, hence the CLI.
  # Move it to the azapi provider once the experiment succeeds.
  az storage account update \
    --resource-group "$RESOURCE_GROUP" --name "$STORAGE_ACCOUNT" \
    --enable-smb-oauth true --output none
  ok "SMB OAuth enabled"
}

preflight() {
  step "Preflight"
  check_supported_os
  check_azure_session
}

# ----------------------------------------------------------- client setup ----

install_packages() {
  install_azfilesauth
  install_cifs_utils
}

install_azfilesauth() {
  if command -v azfilesauthmanager >/dev/null; then
    ok "azfilesauth present"
    return
  fi
  local tmp
  tmp="$(mktemp -d)"
  curl -sSL -o "${tmp}/prod.deb" \
    "https://packages.microsoft.com/config/ubuntu/${OS_VERSION_ID}/packages-microsoft-prod.deb"
  sudo dpkg -i "${tmp}/prod.deb" >/dev/null 2>&1
  rm -rf "$tmp"
  sudo apt-get update -qq >/dev/null
  sudo apt-get install -y -qq azfilesauth >/dev/null
  ok "azfilesauth installed"
}

install_cifs_utils() {
  if command -v mount.cifs >/dev/null; then
    ok "cifs-utils present"
    return
  fi
  sudo apt-get install -y -qq cifs-utils >/dev/null
  ok "cifs-utils installed"
}

# cifs.upcall resolves the service ticket through the krb5 library. With no
# krb5.conf there is no default_realm, so it cannot match the cached ticket.
ensure_krb5_conf() {
  if [ -f "$KRB5_CONF" ] && grep -q "default_realm" "$KRB5_CONF"; then
    ok "krb5 default realm set"
    return
  fi
  sudo tee "$KRB5_CONF" >/dev/null <<EOF
[libdefaults]
    default_realm = ${KERBEROS_REALM}
    dns_lookup_realm = false
    dns_lookup_kdc = false
    default_ccache_name = FILE:/tmp/krb5cc_%{uid}
EOF
  ok "krb5 default realm written to ${KRB5_CONF}"
}

setup_client() {
  step "Client setup"
  install_packages
  ensure_krb5_conf
}

# -------------------------------------------------------- authentication ----

authenticate() {
  step "Authentication"
  request_access_token
  store_credential
}

request_access_token() {
  ACCESS_TOKEN="$(az account get-access-token --resource "$TOKEN_AUDIENCE" \
    --query accessToken -o tsv)"
  assert_token_audience
}

# The audience must have no trailing slash, or the mount is refused.
assert_token_audience() {
  local aud
  aud="$(read_token_claim aud)"
  [ "$aud" = "$TOKEN_AUDIENCE" ] ||
    die "Token audience is '${aud}', expected '${TOKEN_AUDIENCE}'."
  ok "token issued for ${TOKEN_AUDIENCE}"
}

read_token_claim() {
  printf '%s' "$ACCESS_TOKEN" | cut -d. -f2 | decode_jwt_claim "$1"
}

decode_jwt_claim() {
  local claim="$1"
  python3 -c "
import sys, base64, json
payload = sys.stdin.read().strip()
payload += '=' * (-len(payload) % 4)
print(json.loads(base64.urlsafe_b64decode(payload)).get('${claim}', ''))"
}

store_credential() {
  sudo azfilesauthmanager set "$ENDPOINT" "$ACCESS_TOKEN" >/dev/null 2>&1 ||
    die "azfilesauthmanager could not store the token."
  ok "kerberos ticket cached$(ticket_expiry_suffix)"
}

ticket_expiry_suffix() {
  local expiry
  expiry="$(read_ticket_expiry)"
  [ -n "$expiry" ] && printf ', expires %s' "$expiry"
}

read_ticket_expiry() {
  command -v klist >/dev/null || return 0
  resolve_credential_uid_quiet
  sudo klist -c "/tmp/krb5cc_${CRED_UID}" 2>/dev/null |
    awk '/cifs\//{print $3; exit}'
}

# --------------------------------------------------------------- mounting ----

# azfilesauth writes the uid owning the credential cache as USER_UID.
read_cruid_from_config() {
  sudo grep -oP '(?<=^USER_UID:)\s*\K\d+' "$CONFIG_FILE" 2>/dev/null || true
}

resolve_credential_uid_quiet() {
  [ -n "$CRED_UID" ] && return 0
  CRED_UID="${CRUID:-$(read_cruid_from_config)}"
  [ -n "$CRED_UID" ] || CRED_UID="$(id -u)"
}

prepare_mount_point() {
  sudo mkdir -p "$MOUNT_POINT"
  ! mountpoint -q "$MOUNT_POINT" || die "${MOUNT_POINT} is already mounted."
}

# Returns non-zero on failure so callers decide whether to give up.
try_mount() {
  sudo mount -t cifs "$UNC_PATH" "$MOUNT_POINT" \
    -o "sec=krb5,cruid=${CRED_UID},${MOUNT_OPTIONS}" 2>&1
}

mount_share() {
  step "Mount"
  resolve_credential_uid_quiet
  prepare_mount_point
  local output
  if ! output="$(try_mount)"; then
    printf '%s\n' "$output" >&2
    die "$(mount_failure_hint)"
  fi
  ok "${UNC_PATH} -> ${MOUNT_POINT}"
}

# mount.cifs reports errno, and the two we care about mean different things.
mount_failure_hint() {
  cat <<'HINT'
Mount refused. Read the errno above:
  error(13) Permission denied  the plain SMB Share Contributor role is not
                               enough, this path needs a privileged role
  error(2)  No such file       the kernel never ran cifs.upcall, so no Kerberos
                               blob was built. Run --debug to confirm.
HINT
}

# ---------------------------------------------------------------- summary ----

print_summary() {
  step "Mounted"
  field "Account" "$STORAGE_ACCOUNT"
  field "Share" "$SHARE_NAME"
  field "Mount point" "$MOUNT_POINT"
  field "Capacity" "$(read_capacity)"
  field "Identity" "$(az account show --query user.name -o tsv)"
  field "Auth" "Entra ID token over SMB, no storage account key"
  field "Role" "$(read_share_roles)"
  local expiry
  expiry="$(read_ticket_expiry)"
  [ -n "$expiry" ] && field "Ticket until" "$expiry"
  printf '\n  Unmount with: scripts/mount-file-share.sh --cleanup\n'
}

read_capacity() {
  df -h --output=size,used,avail "$MOUNT_POINT" 2>/dev/null |
    tail -1 | awk '{printf "%s total, %s used, %s free", $1, $2, $3}'
}

read_share_roles() {
  local scope
  scope="$(az storage account show -g "$RESOURCE_GROUP" -n "$STORAGE_ACCOUNT" \
    --query id -o tsv 2>/dev/null)"
  az role assignment list --scope "$scope" --include-inherited \
    --query "[?contains(roleDefinitionName,'Storage File')].roleDefinitionName" \
    -o tsv 2>/dev/null | sort -u | paste -sd', ' - || echo "unknown"
}

# ------------------------------------------------------------- diagnostics ----

install_krb5_tools() {
  command -v klist >/dev/null && return 0
  sudo apt-get install -y -qq krb5-user >/dev/null
}

show_account_settings() {
  step "Storage account identity settings"
  az storage account show -g "$RESOURCE_GROUP" -n "$STORAGE_ACCOUNT" \
    --query "azureFilesIdentityBasedAuthentication" -o json
}

show_role_assignments() {
  step "Roles on the storage account"
  local scope
  scope="$(az storage account show -g "$RESOURCE_GROUP" -n "$STORAGE_ACCOUNT" --query id -o tsv)"
  az role assignment list --scope "$scope" --include-inherited \
    --query "[].{role:roleDefinitionName,principal:principalName}" -o table ||
    warn "could not list role assignments"
}

show_token_claims() {
  step "Access token claims"
  request_access_token
  local claim
  for claim in aud idtyp appid oid upn scp; do
    field "$claim" "$(read_token_claim "$claim")"
  done
}

# The kernel upcall reads this cache. Whatever it holds is what SMB presents.
show_credential_cache() {
  step "Kerberos credential cache"
  resolve_credential_uid_quiet
  local cache="/tmp/krb5cc_${CRED_UID}"
  [ -e "$cache" ] || {
    warn "${cache} does not exist"
    return
  }
  sudo klist -c "$cache" 2>&1 || warn "the cache could not be read"
}

# cifs.upcall logs to the journal. Its absence during a mount means the kernel
# never invoked it, which is a different failure from a rejected ticket.
show_upcall_log() {
  step "cifs.upcall activity"
  sudo journalctl --since "$1" --no-pager 2>/dev/null |
    grep -iE "cifs\.upcall|azfilesauth|CIFS" | tail -30 ||
    warn "no journal entries found"
}

show_kernel_messages() {
  step "Recent CIFS kernel messages"
  sudo dmesg 2>/dev/null | grep -i cifs | tail -10 || warn "dmesg unavailable"
}

set_cifs_verbosity() {
  echo "$1" | sudo tee /proc/fs/cifs/cifsFYI >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------ modes ----

run_experiment() {
  preflight
  verify_smb_oauth
  setup_client
  authenticate
  mount_share
  print_summary
}

diagnose() {
  preflight
  install_krb5_tools
  show_account_settings
  show_role_assignments
  show_token_claims
  show_credential_cache
  show_kernel_messages
}

debug_mount() {
  preflight
  setup_client
  set_cifs_verbosity 1
  authenticate

  local since
  since="$(date '+%Y-%m-%d %H:%M:%S')"

  step "Mount attempt"
  resolve_credential_uid_quiet
  prepare_mount_point
  if try_mount; then
    ok "mounted on ${MOUNT_POINT}"
  else
    warn "mount refused, collecting logs"
  fi

  show_kernel_messages
  show_upcall_log "$since"
  set_cifs_verbosity 0
}

unmount_share() {
  if mountpoint -q "$MOUNT_POINT"; then
    sudo umount "$MOUNT_POINT"
    ok "unmounted ${MOUNT_POINT}"
  else
    ok "nothing mounted on ${MOUNT_POINT}"
  fi
}

clear_credential() {
  command -v azfilesauthmanager >/dev/null || return 0
  if sudo azfilesauthmanager clear "$ENDPOINT" >/dev/null 2>&1; then
    ok "credential cleared"
  else
    warn "no credential to clear"
  fi
}

cleanup() {
  step "Cleanup"
  unmount_share
  clear_credential
}

main() {
  case "${1:-}" in
    "") run_experiment ;;
    --enable)
      preflight
      enable_smb_oauth
      setup_client
      authenticate
      mount_share
      print_summary
      ;;
    --diagnose) diagnose ;;
    --debug) debug_mount ;;
    --cleanup) cleanup ;;
    *) die "Unknown option '${1}'. Use --enable, --diagnose, --debug, --cleanup, or no option." ;;
  esac
}

main "$@"
