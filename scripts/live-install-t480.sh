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

  validate_disk_path "$disk"

  if [[ ! -b "$disk" ]]; then
    echo "Disk path is not a block device: $disk" >&2
    exit 1
  fi

  validate_disk_metadata "$disk"
}

validate_disk_path() {
  local disk=$1

  if [[ ! "$disk" =~ ^/dev/(disk/by-id/[a-zA-Z0-9._:+-]+|nvme[0-9]+n[0-9]+|sd[a-z]+|vd[a-z]+|mmcblk[0-9]+)$ ]] ||
    [[ "$disk" == *-part[0-9]* ]]; then
    echo "Refusing suspicious disk path: $disk" >&2
    echo "Use a whole-disk path like /dev/nvme0n1 or /dev/disk/by-id/<disk>." >&2
    exit 1
  fi
}

validate_disk_metadata() {
  local disk=$1

  if [[ "$(lsblk --nodeps --noheadings --raw --output TYPE "$disk")" != "disk" ]]; then
    echo "Refusing a device that is not a whole disk: $disk" >&2
    exit 1
  fi

  if [[ "$(lsblk --nodeps --noheadings --raw --output RO "$disk")" != "0" ]]; then
    echo "Refusing a read-only disk: $disk" >&2
    exit 1
  fi
}

require_unused_disk() {
  local disk=$1
  local mountpoints
  local targets
  local target

  # Includes descendants and [SWAP], protecting the live USB and mounted systems.
  if ! mountpoints=$(lsblk --noheadings --raw --output MOUNTPOINTS "$disk"); then
    echo "Could not inspect disk mounts; refusing to continue." >&2
    exit 1
  fi
  if [[ -n "${mountpoints//[[:space:]]/}" ]]; then
    echo "Refusing a disk with mounted filesystems or active swap: $disk" >&2
    exit 1
  fi

  if ! targets=$(findmnt --noheadings --raw --output TARGET); then
    echo "Could not inspect existing mounts; refusing to continue." >&2
    exit 1
  fi
  while IFS= read -r target; do
    if [[ "$target" == "/mnt" || "$target" == /mnt/* ]]; then
      echo "Refusing to install while $target is already mounted." >&2
      exit 1
    fi
  done <<<"$targets"
}

confirm_disk() {
  local disk=$1
  local confirmation

  lsblk --output NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS "$disk"
  echo "WARNING: This will erase ALL partitions and data on $disk."
  printf 'Type exactly "ERASE %s" to continue: ' "$disk"
  if ! IFS= read -r confirmation || [[ "$confirmation" != "ERASE $disk" ]]; then
    echo "Disk erasure not confirmed; nothing was formatted." >&2
    exit 1
  fi
}

run_disko() {
  local repo_root=$1

  nix --extra-experimental-features "nix-command flakes" run "$repo_root#disko" -- \
    --mode destroy,format,mount --flake "$repo_root#t480"
}

clear_old_signatures() {
  local disk=$1
  local devices path type disk_seen=0
  local -a partitions=()

  if ! devices=$(lsblk --list --paths --noheadings --raw --output PATH,TYPE "$disk"); then
    echo "Could not inspect disk partitions; refusing to erase signatures." >&2
    exit 1
  fi
  while read -r path type; do
    [[ -z "$path" ]] && continue
    case "$type" in
      disk)
        [[ "$(readlink -f "$path")" == "$(readlink -f "$disk")" && "$disk_seen" == 0 ]] || exit 1
        disk_seen=1
        ;;
      part) partitions+=("$path") ;;
      *) echo "Refusing an active or unsupported child device: $path ($type)" >&2; exit 1 ;;
    esac
  done <<<"$devices"
  if [[ "$disk_seen" != 1 ]]; then
    echo "Target disk missing from lsblk output; refusing to continue." >&2
    exit 1
  fi

  # Disko can preserve an old filesystem signature even after repartitioning.
  for path in "${partitions[@]}"; do
    wipefs --all "$path"
  done
  wipefs --all "$disk"
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
  local command_name
  for command_name in nix nixos-install nixos-generate-config nixos-enter lsblk readlink findmnt mountpoint wipefs; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      echo "Missing required live-ISO command: $command_name" >&2
      exit 1
    fi
  done
  validate_disk "$disk_arg"
  require_unused_disk "$disk_arg"

  repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
  host_dir="$repo_root/modules/hosts/t480"

  if [[ ! -f "$repo_root/flake.nix" ]]; then
    echo "flake.nix not found at repo root: $repo_root" >&2
    exit 1
  fi

  if [[ "$repo_root" == "/mnt" || "$repo_root" == /mnt/* ]]; then
    echo "Clone the repo into the live environment, not under /mnt." >&2
    exit 1
  fi

  confirm_disk "$disk_arg"
  stable_disk=$(resolve_stable_disk "$disk_arg")
  validate_disk "$stable_disk"
  write_disk_file "$host_dir/_disk-device.nix" "$stable_disk"

  echo "Using install disk: $stable_disk"
  echo "Rewrote $host_dir/_disk-device.nix"

  # Resolve inputs and catch configuration/account errors before erasing anything.
  nix --extra-experimental-features "nix-command flakes" flake lock "$repo_root"
  nix --extra-experimental-features "nix-command flakes" eval --raw \
    "$repo_root#nixosConfigurations.t480.config.home-manager.users.${user_name}.home.username" >/dev/null
  nix --extra-experimental-features "nix-command flakes" eval --raw \
    "$repo_root#nixosConfigurations.t480.config.system.build.toplevel.drvPath" >/dev/null

  require_unused_disk "$disk_arg"
  validate_disk "$stable_disk"
  if [[ "$(readlink -f "$disk_arg")" != "$(readlink -f "$stable_disk")" ]]; then
    echo "Disk identifier changed during preflight; refusing to continue." >&2
    exit 1
  fi
  require_unused_disk "$stable_disk"
  clear_old_signatures "$stable_disk"
  run_disko "$repo_root"

  if ! mountpoint -q /mnt; then
    echo "Expected disko to mount the target filesystem at /mnt." >&2
    exit 1
  fi

  nixos-generate-config --no-filesystems --root /mnt
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

Also commit flake.lock, which records the exact dependency revisions used.
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
