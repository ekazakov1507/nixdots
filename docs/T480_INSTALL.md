# ThinkPad T480 NixOS Install Guide

This guide installs this flake onto a Lenovo ThinkPad T480.

It is a full-disk install. The selected internal disk will be erased.

## Result

- Host: `t480`
- User: `user`
- Boot: Libreboot GRUB payload loading NixOS-generated GRUB config
- Disk: GPT, 1 GiB unencrypted `/boot`, encrypted LUKS root
- Filesystem: Btrfs subvolumes for `/`, `/home`, and `/nix`
- Desktop: Niri through UWSM
- Shell: Noctalia
- Login screen: SDDM with the local `t480-noctalia` theme
- Power: TLP, thermald, upower, and zram swap
- Editor: Neovim with LazyVim bootstrap

## Before You Start

You need:

- A Lenovo ThinkPad T480.
- The T480 charger connected.
- A USB stick, 8 GB or larger.
- A working internet connection during install.
- A GitHub repo containing this `nixdots` repository.
- A backup of anything important on the T480.
- A T480 already flashed with Libreboot using the GRUB payload path.

Do not use this guide for dual boot. The Disko layout in this repo is designed for full-disk NixOS.

## 1. Push This Repo From Windows

From Windows PowerShell:

```powershell
cd C:\Users\user\nixdots
git status
git add .
git commit -m "Add T480 NixOS flake"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USER/nixdots.git
git push -u origin main
```

If the remote already exists, skip `git remote add origin ...`.

For the first install, the simplest path is a public GitHub repo. If the repo is private, prepare GitHub authentication for the live ISO before starting.

## 2. Download the NixOS ISO

Open the official NixOS download page:

https://nixos.org/download/

For the T480, download:

- NixOS
- Graphical ISO image
- 64-bit Intel/AMD

The minimal ISO also works, but the graphical ISO is easier because it gives you a terminal and network tools in a live desktop.

The desktop you choose in the live ISO does not decide the installed desktop. This flake installs Niri and Noctalia.

## 3. Create the USB Installer From Windows

Use a USB writing tool that writes the ISO image directly to the USB stick.

Recommended simple option:

1. Install balenaEtcher.
2. Select the downloaded NixOS ISO.
3. Select the USB stick.
4. Flash the USB stick.

Alternative option:

1. Use Rufus.
2. Select the downloaded NixOS ISO.
3. Select the USB stick.
4. If Rufus asks for ISO mode or DD mode, choose DD mode.

Do not copy the ISO file onto the USB stick as a normal file. The image must be written directly to the USB device.

## 4. Boot the Installer on Libreboot

1. Shut down the T480.
2. Insert the USB stick.
3. Turn on the laptop.
4. At the Libreboot GRUB menu, choose the option that searches external media for a GRUB configuration.
5. If that does not work, choose the ISOLINUX parser option if your Libreboot menu provides one.
6. If automatic USB boot does not work, press `c` in Libreboot GRUB and boot the ISO manually from the GRUB shell.

This guide assumes Libreboot's GRUB payload. It does not rely on Lenovo UEFI setup, Secure Boot settings, EFI boot entries, or systemd-boot.

If your Libreboot ROM uses SeaBIOS instead of the GRUB payload, this flake's boot settings are not enough by themselves because `boot.loader.grub.device = "nodev"` does not install an MBR bootloader.

## 5. Boot the NixOS Live Environment

When the NixOS boot menu appears, choose the default graphical option.

After the live desktop loads, open a terminal and become root:

```bash
sudo -i
```

If you need a different keyboard layout, set it now. Example for US layout:

```bash
loadkeys us
```

## 6. Connect to the Internet

Ethernet is easiest. If using Wi-Fi, run:

```bash
nmtui
```

Choose:

```text
Activate a connection
```

Then select your Wi-Fi network and enter the password.

Check connectivity:

```bash
ping -c 3 github.com
```

If this fails, fix networking before continuing.

## 7. Clone the Flake Repo

Replace the URL with your GitHub repo:

```bash
git clone https://github.com/YOUR_GITHUB_USER/nixdots.git
cd nixdots
```

If `git` is missing in the live environment:

```bash
nix-shell -p git --run "git clone https://github.com/YOUR_GITHUB_USER/nixdots.git"
cd nixdots
```

## 8. Identify the Install Disk

List disks:

```bash
lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS
```

Typical T480 internal NVMe disk:

```text
/dev/nvme0n1
```

Typical SATA SSD:

```text
/dev/sda
```

Choose the whole internal disk, not a partition.

Correct examples:

```text
/dev/nvme0n1
/dev/sda
/dev/disk/by-id/nvme-SAMSUNG_...
```

Wrong examples:

```text
/dev/nvme0n1p1
/dev/sda1
```

The USB installer will also appear in `lsblk`. Do not select the USB stick.

## 9. Run the Installer

This command erases the selected disk.

For the normal T480 NVMe case:

```bash
bash scripts/live-install-t480.sh /dev/nvme0n1
```

For a SATA SSD:

```bash
bash scripts/live-install-t480.sh /dev/sda
```

Expected prompts:

- Nix may ask whether to accept flake configuration for the Noctalia binary cache. Answer yes.
- Disk encryption will ask for a LUKS passphrase. Save this password.
- `nixos-install` will ask for a root password.
- The script will ask for the default `user` account password.

The script does these steps:

1. Validates the disk path.
2. Resolves a stable `/dev/disk/by-id/...` path when possible.
3. Rewrites `modules/hosts/t480/_disk-device.nix`.
4. Runs Disko to partition, format, encrypt, and mount the disk at `/mnt`.
5. Runs `nixos-generate-config --root /mnt`.
6. Copies generated hardware config into `modules/hosts/t480/_hardware-configuration.nix`.
7. Runs `nixos-install --root /mnt --flake .#t480`.
8. Copies the finalized repo into `/home/user/nixdots` on the installed system.
9. Sets the password for `user`.

The installed boot path is Libreboot-specific:

1. NixOS generates `/boot/grub/grub.cfg`.
2. NixOS copies kernels and initrds into `/boot/kernels`.
3. Libreboot's GRUB payload scans the separate `/boot` partition.
4. Because `/boot` is a separate partition, Libreboot sees the config as `/grub/grub.cfg` on that partition.

If you changed the username in the Nix files before install, pass the same name:

```bash
T480_USER=YOUR_USER bash scripts/live-install-t480.sh /dev/nvme0n1
```

Do not use `T480_USER` unless you also changed the hardcoded username in the repo modules.

## 10. Reboot

After the script finishes:

```bash
reboot
```

Remove the USB stick when the machine restarts.

On boot:

1. Libreboot GRUB should find the NixOS GRUB config on `/boot`.
2. Choose the NixOS entry if a menu is shown.
3. Enter the LUKS disk encryption password when the NixOS initrd asks for it.
4. Wait for SDDM.
5. Log in as `user`.
6. Use the password you set during install.
7. If SDDM asks for a session, choose `Niri (UWSM)`.

## 11. First Boot Checks

Open a terminal in Niri.

Check the copied repo:

```bash
cd ~/nixdots
git status --short
```

Check batteries:

```bash
ls /sys/class/power_supply
```

Expected battery names are usually:

```text
BAT0
BAT1
```

Check TLP:

```bash
sudo tlp-stat -s
sudo tlp-stat -b
```

Check SDDM theme installation:

```bash
ls /run/current-system/sw/share/sddm/themes
```

You should see:

```text
t480-noctalia
```

Check Libreboot boot files:

```bash
test -f /boot/grub/grub.cfg
ls /boot/kernels
```

There should be a GRUB config file and copied kernel/initrd files. This is what Libreboot's GRUB payload loads.

Check brightness keys, volume keys, media keys, touchpad, TrackPoint, Wi-Fi, Bluetooth, audio, suspend, and resume.

If a key does not behave correctly, run:

```bash
wev
```

Press the key and check the emitted key name.

Start Neovim:

```bash
nvim
```

The first LazyVim launch may download plugins, so it needs internet access.

## 12. Commit Generated Machine Files

The installer copied the finalized repo into:

```text
/home/user/nixdots
```

Commit the generated files from the installed T480:

```bash
cd ~/nixdots
git status --short
git add modules/hosts/t480/_disk-device.nix modules/hosts/t480/_hardware-configuration.nix
test -f flake.lock && git add flake.lock
git commit -m "Capture T480 generated hardware config"
git push
```

If GitHub asks for credentials over HTTPS, use a GitHub token or configure SSH.

## 13. Rebuild Later

After future changes:

```bash
cd ~/nixdots
git pull
sudo nixos-rebuild build --flake .#t480
sudo nixos-rebuild switch --flake .#t480
```

If a switch breaks the desktop, reboot and choose an older generation in the boot menu.

## Troubleshooting

If the installer refuses the disk path, you probably selected a partition. Use a whole disk like `/dev/nvme0n1`, not `/dev/nvme0n1p1`.

If networking fails, run `nmtui` again or use Ethernet. The install needs network access for the flake inputs and packages.

If SDDM opens but login fails, press `Ctrl+Alt+F2`, log in on a text console, and inspect:

```bash
systemctl status sddm --no-pager
journalctl -b -u sddm --no-pager
```

If Niri starts but the shell does not appear, run:

```bash
noctalia-shell
```

If Noctalia power profile controls are missing, that is expected with this repo. The T480 power stack uses TLP instead of `power-profiles-daemon`.

If Libreboot does not find NixOS after installation, use the Libreboot GRUB menu to search for GRUB configuration files. The expected config is `/grub/grub.cfg` on the separate `/boot` partition, which appears as `/boot/grub/grub.cfg` after Linux is booted.

Do not add `boot.loader.grub.target = "i386-coreboot"` to this flake. Current NixOS exposes `boot.loader.grub.device = "nodev"` for generating a GRUB menu without installing GRUB itself; Libreboot already provides the coreboot GRUB payload.

## Reference Links

- NixOS download page: https://nixos.org/download/
- NixOS manual, installation chapter: https://nixos.org/manual/nixos/stable/index.html#chap-installation
- Disko project and CLI flow: https://github.com/nix-community/disko
- Libreboot Linux boot guide: https://libreboot.org/docs/linux/
- Libreboot installer USB guide: https://libreboot.org/docs/linux/grub_boot_installer.html
