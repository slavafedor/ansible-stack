#!/bin/bash
# Creates or adjusts the ../../local folder structure expected by the
# eol-ansible-stack docker-compose.yml and ansible.cfg.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/local"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[create]${NC}  $1"; }
skip()    { echo -e "${YELLOW}[exists]${NC}  $1"; }

makedirs() {
    for d in "$@"; do
        if [[ -d "$d" ]]; then
            skip "$d"
        else
            mkdir -p "$d"
            info "$d"
        fi
    done
}

touchfile() {
    local path="$1" mode="${2:-}"
    if [[ -e "$path" ]]; then
        skip "$path"
    else
        touch "$path"
        [[ -n "$mode" ]] && chmod "$mode" "$path"
        info "$path"
    fi
}

writefile() {
    local path="$1" content="$2"
    if [[ -e "$path" ]]; then
        skip "$path"
    else
        printf '%s\n' "$content" > "$path"
        info "$path"
    fi
}

symlink() {
    local target="$1" link="$2"
    if [[ -L "$link" ]]; then
        skip "$link -> $(readlink "$link")"
    elif [[ -e "$link" ]]; then
        echo "[skip]    $link already exists and is not a symlink — leaving it"
    else
        ln -s "$target" "$link"
        info "$link -> $target"
    fi
}

echo "Target: $LOCAL_DIR"
echo

# ── Directories ──────────────────────────────────────────────────────────────
makedirs \
    "$LOCAL_DIR/files" \
    "$LOCAL_DIR/inventory/group_vars/all" \
    "$LOCAL_DIR/inventory/host_vars" \
    "$LOCAL_DIR/ssh-keys/ansible" \
    "$LOCAL_DIR/ssh-keys/root" \
    "$LOCAL_DIR/vault"

# ── SSH key dirs: restrictive permissions ─────────────────────────────────────
chmod 700 "$LOCAL_DIR/ssh-keys/ansible"
chmod 700 "$LOCAL_DIR/ssh-keys/root"

# ── Bash history files ────────────────────────────────────────────────────────
touchfile "$LOCAL_DIR/ansible-history"
touchfile "$LOCAL_DIR/root-history"

# ── Vault password file ───────────────────────────────────────────────────────
touchfile "$LOCAL_DIR/vault/.vault_pass" 600

# ── Vault passwords template (unencrypted placeholder) ───────────────────────
writefile "$LOCAL_DIR/vault/passwords.yml" \
'---
vault_passwords: {}
#  "hostname-or-ip":
#    username: "password"

vault_passwords_by_hostname: {}
#  SHORTNAME:
#    username: "password"

vault_ssh_key_passphrases: {}
#  id_ed25519: "passphrase"

vault_service_credentials: {}
#  smtp:
#    username: "user"
#    password: "pass"'

# ── Symlink passwords.yml into group_vars so Ansible finds it ─────────────────
symlink "../../../vault/passwords.yml" \
    "$LOCAL_DIR/inventory/group_vars/all/passwords.yml"

# ── group_vars/all/all.yml ────────────────────────────────────────────────────
writefile "$LOCAL_DIR/inventory/group_vars/all/all.yml" \
'---
host_info:
  hostname: "{{ inventory_hostname }}"
  ansible_host: "{{ ansible_host | default("") }}"
  inventory_hostname: "{{ inventory_hostname }}"
  ansible_user: "{{ ansible_user | default("daq") }}"

ansible_password: >-
  {{
    (vault_passwords | default({}))
    | get_vault_password(
        ansible_host | default(inventory_hostname),
        ansible_user | default("daq"),
        inventory_hostname
      )
  }}

ansible_become_password: >-
  {{
    vault_passwords_by_hostname | default({})
    | get_vault_password(inventory_hostname, ansible_user | default("daq"))
    | default(
        vault_passwords | default({})
        | get_vault_password(
            ansible_host | default(inventory_hostname),
            ansible_user | default("daq")
          )
      )
  }}

ansible_ssh_private_key_file: "~/.ssh/id_ed25519"
ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ansible_python_interpreter: /usr/bin/python3
ansible_connection: ssh
ansible_timeout: 30'

# ── Inventory placeholder ──────────────────────────────────────────────────────
writefile "$LOCAL_DIR/inventory/inventory.ini" \
'# Local inventory — add your DSM hosts here
[DSMs]
# fl1  ansible_host=fl1.guestnet.ucar.edu  ansible_user=daq  dashboard_dsm_selector="5,-1"
# lab1 ansible_host=128.117.78.173         ansible_user=daq  dashboard_dsm_selector="1,-1"

[all:vars]
ansible_ssh_common_args='\''-o StrictHostKeyChecking=no'\''
ansible_python_interpreter=/usr/bin/python3'

echo
echo "Done. Local structure at: $LOCAL_DIR"
echo
echo "Next steps:"
echo "  1. Add hosts to $LOCAL_DIR/inventory/inventory.ini"
echo "  2. Fill in $LOCAL_DIR/vault/passwords.yml, then encrypt:"
echo "       ansible-vault encrypt $LOCAL_DIR/vault/passwords.yml"
echo "  3. Set vault password in $LOCAL_DIR/vault/.vault_pass (chmod 600)"
echo "  4. Copy SSH keys into $LOCAL_DIR/ssh-keys/ansible/ and ssh-keys/root/"
