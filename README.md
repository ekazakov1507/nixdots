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

The display module enables SDDM on Wayland, uses the UWSM-managed `niri-uwsm` session by default, and packages the local `t480-noctalia` Qt6 theme into the system profile.

The boot module disables systemd-boot and EFI variable writes. It enables GRUB with `device = "nodev"` so NixOS generates `/boot/grub/grub.cfg` and copied kernels for Libreboot's GRUB payload to load.

The laptop module enables `thermald`, `tlp`, `upower`, and `zramSwap`. `power-profiles-daemon` is intentionally not enabled because it conflicts with TLP.

The base module enables PipeWire with PulseAudio compatibility and `rtkit`, so Noctalia audio controls, `playerctl`, and `pavucontrol` all have an actual audio backend.

The Noctalia module adds:

- the Noctalia flake package and Home Manager module
- official plugin registry support
- the `niri-overview-launcher` plugin
- `cliphist`, `imagemagick`, `python3`, and `wlsunset`
- `xdg-desktop-portal` with the GTK file chooser portal for Niri

Noctalia is the primary shell layer now. Niri starts `noctalia-shell` directly at session startup, and the main launcher, control center, settings, lock screen, volume, and brightness keybinds all go through Noctalia IPC.

The user module also writes an explicit `niri/config.kdl` so the T480 does not rely on upstream defaults for:

- Noctalia compositor integration for rounded windows, wallpaper backdrop placement, and notification activation
- screen brightness keys via Noctalia IPC
- volume and mic mute keys via Noctalia IPC
- media keys via `playerctl`

`wev` is installed for checking the exact key names if any ThinkPad key behaves differently than expected.

Waybar is explicitly configured under `~/.config/waybar` to show:

- total battery status
- `BAT0`
- `BAT1`

This assumes the T480 exposes its two batteries as `BAT0` and `BAT1`, which is the normal Linux layout for this class of ThinkPad. Confirm it after first boot with `ls /sys/class/power_supply`.

The Waybar files are now only a fallback reference. The active shell is Noctalia.

The editor module installs a LazyVim-based Neovim setup. It enables Home Manager `programs.neovim`, writes the LazyVim bootstrap under `~/.config/nvim`, and installs the tools LazyVim expects on Linux, including `fd`, `fzf`, `lazygit`, `ripgrep`, `tree-sitter`, and a C compiler.

For Nix development, the LazyVim config also enables the official Nix extra and uses Nix-managed `nil`, `nixfmt`, and `statix` instead of relying on Mason for those tools.

## Authoring Flow

1. Initialize the repo locally and add your GitHub remote.
2. If you already have a working Nix installation on another machine, run `nix flake lock` and commit `flake.lock`.
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

1. Validate the disk path.
2. Resolve a stable `/dev/disk/by-id/...` path when possible.
3. Rewrite `modules/hosts/t480/_disk-device.nix`.
4. Partition, format, and mount the disk with the repo's pinned `disko` input.
5. Generate hardware config and rewrite `modules/hosts/t480/_hardware-configuration.nix`.
6. Run `nixos-install --flake .#t480`.
7. Copy the finalized repo into `/home/user/nixdots` on the installed system.
8. Prompt for the default user password after install.

On first graphical login, SDDM should default to the Niri UWSM session. If it asks for a session, choose `Niri (UWSM)`.

On first `nvim` launch, LazyVim will clone `lazy.nvim` and then install plugins into the user's home directory, so that first startup needs network access.

## After First Boot

The installer copies the finalized repo to `/home/user/nixdots`. Review and commit:

- `modules/hosts/t480/_disk-device.nix`
- `modules/hosts/t480/_hardware-configuration.nix`
- `flake.lock` if it was created during installation

Also verify:

- `sudo tlp-stat -s`
- `sudo tlp-stat -b`
- `ls /sys/class/power_supply`
- `noctalia-shell ipc show`
- `ls /run/current-system/sw/share/sddm/themes`
- `test -f /boot/grub/grub.cfg`
- `ls /boot/kernels`

## Libreboot Notes

- This repo assumes the T480 is booting with Libreboot's GRUB payload.
- NixOS does not install a separate bootloader to the disk; `boot.loader.grub.device = "nodev"` only generates the config and kernel files Libreboot needs.
- Do not add `boot.loader.grub.target = "i386-coreboot"` to this flake. That is not a current NixOS option and would break evaluation.
- The Disko layout uses a normal 1 GiB Linux `/boot` partition. Because `/boot` is mounted separately, Libreboot sees NixOS's `/boot/grub/grub.cfg` as `/grub/grub.cfg` on that partition.

## T480 Key Notes

- Screen brightness keys should map through Niri as `XF86MonBrightnessUp` and `XF86MonBrightnessDown`.
- Audio and media keys should map through Niri as the standard `XF86Audio*` keys.
- Keyboard backlight toggle and some firmware-level ThinkPad functions are not compositor features; they are handled by the laptop firmware or kernel support rather than by Niri binds.
- If a key does not work as expected, run `wev` inside Niri and press the key to confirm the emitted symbol, then adjust `modules/features/user.nix`.

## Power Notes

- The T480 is a good TLP target. The repo now uses TLP rather than `power-profiles-daemon`.
- The included TLP settings are conservative CPU power settings only; they do not yet enforce charge thresholds.
- If you later want battery health thresholds, the T480 class supports separate ThinkPad charge controls for `BAT0` and `BAT1`, but those should be chosen deliberately rather than silently enabled.
- Noctalia's documented power-profile integration expects `power-profiles-daemon` or `tuned`. Because this repo keeps TLP for the T480, you should expect Noctalia's power-profile controls to be unavailable unless we later switch away from TLP.

## Noctalia Notes

- The repo uses the Noctalia flake plus its Home Manager module, not a manual `qs` checkout.
- The flake now includes Noctalia's Cachix binary cache to avoid expensive local builds.
- The active Niri shell path is `Niri + Noctalia`, not `Niri + Waybar + Mako`.
- I did not find official stock Noctalia configuration for separate `BAT0` and `BAT1` widgets comparable to Waybar's multi-instance battery module. For now, treat the built-in Noctalia battery integration as the primary shell UI and the Waybar config as the fallback reference for explicit dual-battery display.

## SDDM Notes

- SDDM is configured with `services.displayManager.sddm`, not with manual files under `/etc`.
- The local theme source is `modules/features/display/sddm-theme`; the Nix module packages it into `/run/current-system/sw/share/sddm/themes/t480-noctalia`.
- The default session is `niri-uwsm`, matching the UWSM desktop entry generated by `programs.uwsm.waylandCompositors.niri`.

## LazyVim Notes

- The Neovim bootstrap lives in `modules/features/editors/lazyvim.nix`; Home Manager renders that into `~/.config/nvim`.
- Icons in LazyVim look better with a Nerd Font, but the setup will still run without one.
- After first launch, run `:LazyHealth` inside Neovim to verify providers, external tools, and plugin health.
