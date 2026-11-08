# T480 NixOS Bootstrap

This repository bootstraps a NixOS install for a Lenovo ThinkPad T480.

It is designed to be authored from `c:\Users\user\nixdots`, pushed to GitHub, and then cloned from the NixOS live ISO before installation.

## Stack

- `flake-parts` for flake structure
- `import-tree` for recursive module loading
- `home-manager` for user configuration
- `disko` for partitioning and filesystems
- `nixos-hardware` for the ThinkPad T480 hardware profile

## Layout

- `flake.nix`: flake entrypoint
- `modules/features`: reusable base, laptop, display-manager, desktop, editor, and user modules
- `modules/features/accessibility.nix`: shared visual-accessibility values for the T480 interfaces
- `modules/features/display/sddm.nix`: SDDM login manager with a local T480 Noctalia theme
- `modules/features/shell/noctalia.nix`: Noctalia shell integration layered on top of Niri
- `modules/hosts/t480`: host definition, `disko` layout, and generated host files
- `scripts/live-install-t480.sh`: live ISO installer entrypoint

The files `modules/hosts/t480/_disk-device.nix` and `modules/hosts/t480/_hardware-configuration.nix` are intentionally prefixed with `_` so `import-tree` ignores them. The install script rewrites both files during installation.

## Default Choices

- Hostname: `t480`
- Boot: Libreboot GRUB payload loading NixOS-generated `/boot/grub/grub.cfg`
- Filesystem: unencrypted `/boot`, encrypted Btrfs with `@`, `@home`, and `@nix` subvolumes
- Desktop: Niri
- Shell: Noctalia
- Login manager: SDDM with the `t480-noctalia` theme
- Default user: `user`

If you change the username, update `modules/features/user.nix`, `modules/features/editors/lazyvim.nix`, and `modules/features/shell/noctalia.nix`, then run the installer with `T480_USER=<name>`.

The desktop module enables `programs.niri` with UWSM. It keeps a small Niri-oriented package set around the shell, including `alacritty`, `fuzzel`, `brightnessctl`, `playerctl`, `pavucontrol`, and `xwayland-satellite`.

The display module enables SDDM on Wayland, uses the UWSM-managed `niri-uwsm` session by default, and packages the local `t480-noctalia` Qt6 theme into the system profile. Niri runs with `--session` so its display and IPC environment is imported before graphical services start.

The boot module disables systemd-boot and EFI variable writes. It enables GRUB with `device = "nodev"` so NixOS generates `/boot/grub/grub.cfg` and copied kernels for Libreboot's GRUB payload to load.

The laptop module enables `thermald`, `tlp`, `tlp-pd`, `upower`, and `zramSwap`. TLP's own profiles daemon provides desktop power-mode controls; the separate `power-profiles-daemon` stays disabled because it conflicts with TLP.

The base module enables PipeWire with PulseAudio compatibility and `rtkit`, so Noctalia audio controls, `playerctl`, and `pavucontrol` all have an actual audio backend.

The Noctalia module adds:

- the Noctalia flake package and Home Manager module
- `cliphist`, `imagemagick`, `python3`, and `wlsunset`
- `xdg-desktop-portal` with the GTK file chooser portal for Niri
- Noctalia's authentication agent for graphical administrator prompts
- separate, labeled `BAT0` and `BAT1` battery widgets, including while charging
- a power-profile widget backed by `tlp-pd`

Noctalia is the primary shell layer. Niri starts it through `uwsm app -- noctalia` at session startup, and the main launcher, control center, settings, lock screen, volume, brightness, media, and logout keybinds all go through `noctalia msg`.

The user module also writes an explicit `niri/config.kdl` so the T480 does not rely on upstream defaults for:

- Noctalia compositor integration for rounded windows, wallpaper backdrop placement, and notification activation
- screen brightness keys via Noctalia IPC
- volume and mic mute keys via Noctalia IPC
- media keys via Noctalia IPC

`wev` is installed for checking the exact key names if any ThinkPad key behaves differently than expected.

Waybar is explicitly configured under `~/.config/waybar` to show:

- total battery status
- `BAT0`
- `BAT1`

This assumes the T480 exposes its two batteries as `BAT0` and `BAT1`, which is the normal Linux layout for this class of ThinkPad. Confirm it after first boot with `ls /sys/class/power_supply`.

The Waybar files are only an optional fallback. Noctalia itself now displays both battery widgets; Waybar does not need to run. A battery widget hides if UPower reports that battery as absent, for example when the removable battery is disconnected. The fixed BAT0/BAT1 text labels remain visible.

The editor module installs a LazyVim-based Neovim setup. It enables Home Manager `programs.neovim`, writes the LazyVim bootstrap under `~/.config/nvim`, and installs the tools LazyVim expects on Linux, including `fd`, `fzf`, `lazygit`, `ripgrep`, `tree-sitter`, and a C compiler.

For Nix development, the LazyVim config also enables the official Nix extra and uses Nix-managed `nil`, `nixfmt`, and `statix` instead of relying on Mason for those tools.

## Authoring Flow

1. Initialize the repo locally and add your GitHub remote.
2. On a Linux Nix machine, run the validation commands below and commit `flake.lock`. Without that file, input branches are not reproducibly locked.
3. Push the repo to GitHub.

Full install documentation is in `docs/T480_INSTALL.md`.

## Live ISO Install

From the NixOS live environment:

```bash
sudo -i
git clone <your-repo-url> nixdots
cd nixdots
bash scripts/live-install-t480.sh /dev/nvme0n1
```

The installer script will:

1. Validate the whole disk and reject read-only disks, partitions, mounted filesystems, and active swap.
2. Resolve a stable `/dev/disk/by-id/...` path when possible.
3. Rewrite `modules/hosts/t480/_disk-device.nix`.
4. Require an explicit `ERASE <disk>` confirmation, resolve the lock file, and evaluate the host before running Disko with `--flake .#t480`.
5. Partition, format, and mount the disk, then generate hardware config with `--no-filesystems` so Disko remains the filesystem authority.
6. Run `nixos-install --flake .#t480`.
7. Copy the finalized repo into `/home/user/nixdots` on the installed system.
8. Prompt for the default user password after install.

On first graphical login, SDDM should default to the Niri UWSM session. If it asks for a session, choose `Niri (UWSM)`.

On first `nvim` launch, LazyVim will clone `lazy.nvim` and then install plugins into the user's home directory, so that first startup needs network access.

## After First Boot

The installer copies the finalized repo to `/home/user/nixdots`. Review and commit:

- `modules/hosts/t480/_disk-device.nix`
- `modules/hosts/t480/_hardware-configuration.nix`
- `flake.lock`

Also verify:

- `sudo tlp-stat -s`
- `sudo tlp-stat -b`
- `ls /sys/class/power_supply`
- `upower -e`, then inspect both battery devices with `upower -i <device-path>`
- `noctalia msg status`
- `ls /run/current-system/sw/share/sddm/themes`
- `test -f /boot/grub/grub.cfg`
- `ls /boot/kernels`

Check the Noctalia bar visually: BAT0 and BAT1 should each have their own percentage and charging indicator. Compare both values against UPower with the charger connected and disconnected. Do not assume equal percentages: the T480 can charge and discharge its batteries sequentially.

## Validation

On Linux with Nix, from the committed or staged repository:

```bash
nix flake lock
nix flake check --no-build
nix flake check
nix build .#nixosConfigurations.t480.config.system.build.toplevel --no-link
```

The checks validate the Niri configuration with Niri itself, validate the Noctalia TOML using its Home Manager module, lint and test the installer, and build the system. They do not format any disks. A full check downloads or builds the complete system and can take a while.

The installer tests can also run without Nix, including in Git Bash on Windows:

```bash
bash -n scripts/live-install-t480.sh
bash tests/installer.sh
```

Keep `system.stateVersion` and `home.stateVersion` at the values used for the first installation. These are compatibility settings, not package-update controls; do not raise them just to upgrade inputs.

## Libreboot Notes

- This repo assumes the T480 is booting with Libreboot's GRUB payload.
- NixOS does not install a separate bootloader to the disk; `boot.loader.grub.device = "nodev"` only generates the config and kernel files Libreboot needs.
- Do not add `boot.loader.grub.target = "i386-coreboot"` to this flake. That is not a current NixOS option and would break evaluation.
- The Disko layout uses a normal 1 GiB Linux `/boot` partition. Because `/boot` is mounted separately, Libreboot sees NixOS's `/boot/grub/grub.cfg` as `/grub/grub.cfg` on that partition.

## T480 Key Notes

- Screen brightness keys should map through Niri as `XF86MonBrightnessUp` and `XF86MonBrightnessDown`.
- Audio and media keys should map through Niri as the standard `XF86Audio*` keys.
- The built-in display starts at 125% scale while retaining its native resolution. Use `Super+Ctrl+-` for 100%, `Super+Ctrl+0` to restore 125%, and `Super+Ctrl+=` for 150%. These temporary choices reset to 125% after a Niri configuration reload or new login.
- Keyboard backlight toggle and some firmware-level ThinkPad functions are not compositor features; they are handled by the laptop firmware or kernel support rather than by Niri binds.
- If a key does not work as expected, run `wev` inside Niri and press the key to confirm the emitted symbol, then adjust `modules/features/user.nix`.

## Power Notes

- The T480 is a good TLP target. The repo now uses TLP rather than `power-profiles-daemon`.
- TLP keeps the existing AC and battery CPU policy, with an additional power-saver profile. No charge thresholds are imposed.
- Swap is compressed RAM only. Suspend-to-RAM is supported by the normal laptop stack; hibernation is not configured.
- If you later want battery health thresholds, the T480 class supports separate ThinkPad charge controls for `BAT0` and `BAT1`, but those should be chosen deliberately rather than silently enabled.
- `services.tlp.pd.enable` exposes the PowerProfiles D-Bus interface used by Noctalia. The GUI can select TLP performance, balanced, or power-saver profiles without running a competing power manager.

## Noctalia Notes

- The repo uses Noctalia v5.4.1's native binary and Home Manager module, not the legacy Quickshell shell.
- Noctalia follows the shared visual profile: its panels use 125% UI scale and high contrast, while the top bar uses 125% control scale with 120% text scale.
- The flake includes Noctalia's Cachix binary cache and retains upstream's own nixpkgs input to preserve cache compatibility. Whether a particular build is cached still depends on the locked inputs and cache availability.
- The active Niri shell path is `Niri + Noctalia`, not `Niri + Waybar + Mako`.
- Stock Noctalia supports named battery widgets with a `device` selector. This repo uses `BAT0` and `BAT1` directly, following the [official battery widget reference](https://docs.noctalia.dev/noctalia/bar/widgets/battery/).

## SDDM Notes

- SDDM is configured with `services.displayManager.sddm`, not with manual files under `/etc`.
- GTK applications use 125% text scale and the same 48 px cursor. The local SDDM theme uses the shared 125% login scale for its text, fields, and buttons.
- The local theme source is `modules/features/display/sddm-theme`; the Nix module packages it into `/run/current-system/sw/share/sddm/themes/t480-noctalia`.
- The default session is `niri-uwsm`, matching the UWSM desktop entry generated by `programs.uwsm.waylandCompositors.niri`.

## LazyVim Notes

- The Neovim bootstrap lives in `modules/features/editors/lazyvim.nix`; Home Manager renders that into `~/.config/nvim`.
- Icons in LazyVim look better with a Nerd Font, but the setup will still run without one.
- After first launch, run `:LazyHealth` inside Neovim to verify providers, external tools, and plugin health.
