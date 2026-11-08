#!/usr/bin/env bash

set -euo pipefail

installer=${1:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/scripts/live-install-t480.sh"}
# shellcheck source=../scripts/live-install-t480.sh
source "$installer"

passed=0
log=$(mktemp)
trap 'rm -f "$log"' EXIT

expect_success() {
  local description=$1
  shift
  if ! ("$@") >"$log" 2>&1; then
    echo "FAIL: $description"
    cat "$log"
    exit 1
  fi
  passed=$((passed + 1))
  echo "PASS: $description"
}

expect_failure() {
  local description=$1
  shift
  if ("$@") >"$log" 2>&1; then
    echo "FAIL: $description unexpectedly succeeded"
    exit 1
  fi
  passed=$((passed + 1))
  echo "PASS: $description"
}

# All device inspection below is mocked. No test formats or mounts a device.
lsblk() {
  if [[ "${disk_inspection_fails:-false}" == true ]]; then
    return 1
  fi
  case " $* " in
    *" --output TYPE "*) printf '%s\n' "${disk_type:-disk}" ;;
    *" --output RO "*) printf '%s\n' "${read_only:-0}" ;;
    *" --output MOUNTPOINTS "*) printf '%s\n' "${disk_mounts:-}" ;;
    *) printf 'mock disk information\n' ;;
  esac
}

findmnt() {
  if [[ "${mount_inspection_fails:-false}" == true ]]; then
    return 1
  fi
  printf '%s\n' "${existing_mounts:-/}"
}

expect_success "NVMe whole disk" validate_disk_path /dev/nvme0n1
expect_success "SATA whole disk" validate_disk_path /dev/sda
expect_success "stable disk identifier" validate_disk_path /dev/disk/by-id/nvme-SAMPLE_123
expect_failure "missing argument" bash "$installer"
expect_failure "extra arguments" bash "$installer" /dev/sda /dev/sdb
expect_failure "partition path" validate_disk_path /dev/nvme0n1p1
expect_failure "by-id partition" validate_disk_path /dev/disk/by-id/nvme-SAMPLE-part1
expect_failure "path traversal" validate_disk_path /dev/disk/by-id/../../sda
expect_failure "Nix string injection" validate_disk_path '/dev/disk/by-id/bad"name'
expect_failure "not a disk" validate_disk /dev/null
expect_failure "invalid username" validate_username 'user;reboot'
expect_success "whole-disk metadata" validate_disk_metadata /dev/mock

disk_type=part
expect_failure "partition behind a symlink" validate_disk_metadata /dev/mock
disk_type=disk
read_only=1
expect_failure "read-only disk" validate_disk_metadata /dev/mock
read_only=0

expect_success "unused target" require_unused_disk /dev/mock
disk_inspection_fails=true
expect_failure "failed disk inspection" require_unused_disk /dev/mock
disk_inspection_fails=false
mount_inspection_fails=true
expect_failure "failed mount inspection" require_unused_disk /dev/mock
mount_inspection_fails=false
disk_mounts=/run/iso
expect_failure "live installer disk" require_unused_disk /dev/mock
disk_mounts='[SWAP]'
expect_failure "active swap" require_unused_disk /dev/mock
disk_mounts=
existing_mounts=/mnt/boot
expect_failure "existing target mount" require_unused_disk /dev/mock
existing_mounts=/

expect_failure "unconfirmed wipe" confirm_disk /dev/mock </dev/null
expect_failure "wrong disk confirmation" confirm_disk /dev/mock <<<"ERASE /dev/other"
expect_success "exact wipe confirmation" confirm_disk /dev/mock <<<"ERASE /dev/mock"

check_disko_invocation() {
  local -a captured
  nix() { captured=("$@"); }
  run_disko /example/repo
  [[ ${#captured[@]} -eq 9 && ${captured[3]} == "/example/repo#disko" &&
    ${captured[6]} == "destroy,format,mount" && ${captured[7]} == "--flake" &&
    ${captured[8]} == "/example/repo#t480" ]]
}

expect_success "Disko selects the host flake, not a wrapper file" check_disko_invocation
echo "$passed installer checks passed. No disks were touched."
