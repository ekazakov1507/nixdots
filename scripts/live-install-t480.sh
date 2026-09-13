#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/live-install-t480.sh <disk>

Example:
  bash scripts/live-install-t480.sh /dev/nvme0n1

Optional environment variables:
  T480_USER   Username to pass to passwd after install (default: user)
EOF
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run this script as root from the NixOS live ISO." >&2
    exit 1
  fi
}

validate_username() {
  local username=$1

  if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Refusing invalid username: $username" >&2
    exit 1
  fi
}

validate_disk() {
  local disk=$1

  if [[ ! -b "$disk" ]]; then
    echo "Disk path is not a block device: $disk" >&2
    exit 1
  fi

  case "$disk" in
    /dev/disk/by-id/*|/dev/nvme*n1|/dev/sd[a-z]|/dev/vd[a-z])
      ;;
    *)
      echo "Refusing suspicious disk path: $disk" >&2
      echo "Use a whole-disk path like /dev/nvme0n1 or /dev/disk/by-id/<disk>." >&2
      exit 1
      ;;
  esac
}

resolve_stable_disk() {
  local disk=$1
  local resolved
  local candidate

  resolved=$(readlink -f "$disk")
  candidate=$resolved

  if [[ -d /dev/disk/by-id ]]; then
    while IFS= read -r by_id; do
      if [[ "$by_id" == *-part* ]]; then
        continue
      fi

      if [[ "$(readlink -f "$by_id")" == "$resolved" ]]; then
        candidate=$by_id
        break
      fi
    done < <(find /dev/disk/by-id -maxdepth 1 -type l | sort)
  fi

  printf '%s\n' "$candidate"
}

write_disk_file() {
  local path=$1
  local disk=$2

  cat >"$path" <<EOF
{
  device = "${disk}";
}
EOF
}

copy_repo_to_target() {
  local repo_root=$1
  local user_name=$2
  local target="/mnt/home/${user_name}/nixdots"

  mkdir -p "/mnt/home/${user_name}"

  if [[ -e "$target" ]]; then
    echo "Refusing to overwrite existing installed repo copy: $target" >&2
    exit 1
  fi

  mkdir -p "$target"
  cp -a "$repo_root/." "$target/"
  nixos-enter --root /mnt -c "chown -R ${user_name}:users /home/${user_name}/nixdots"

  echo "Copied finalized repo to /home/${user_name}/nixdots in the installed system."
}

main() {
  local disk_arg=${1-}
  local user_name=${T480_USER:-user}
  local repo_root
  local host_dir
  local stable_disk

  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  require_root
  validate_username "$user_name"
  validate_disk "$disk_arg"

  repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
  host_dir="$repo_root/modules/hosts/t480"

  if [[ ! -f "$repo_root/flake.nix" ]]; then
    echo "flake.nix not found at repo root: $repo_root" >&2
    exit 1
  fi

  stable_disk=$(resolve_stable_disk "$disk_arg")
  write_disk_file "$host_dir/_disk-device.nix" "$stable_disk"

  echo "Using install disk: $stable_disk"
  echo "Rewrote $host_dir/_disk-device.nix"

  nix --extra-experimental-features "nix-command flakes" run "$repo_root#disko" -- \
    --mode destroy,format,mount "$host_dir/disko.nix"

  if ! mountpoint -q /mnt; then
    echo "Expected disko to mount the target filesystem at /mnt." >&2
    exit 1
  fi

  nixos-generate-config --root /mnt
  install -m 0644 /mnt/etc/nixos/hardware-configuration.nix \
    "$host_dir/_hardware-configuration.nix"

  echo "Rewrote $host_dir/_hardware-configuration.nix"
  nixos-install --root /mnt --flake "$repo_root#t480"

  copy_repo_to_target "$repo_root" "$user_name"

  echo "Set a password for the default user account: $user_name"
  nixos-enter --root /mnt -c "passwd $user_name"

  cat <<EOF
Install complete.

After first boot, commit these generated files from /home/${user_name}/nixdots:
  modules/hosts/t480/_disk-device.nix
  modules/hosts/t480/_hardware-configuration.nix

If flake.lock was created during installation, commit that too.
EOF
}

main "$@"
