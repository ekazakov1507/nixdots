{ ... }:
{
  flake.nixosModules.librebootGrub = { lib, ... }: {
    boot.loader = {
      timeout = 5;

      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = false;
        copyKernels = true;
        configurationLimit = 20;
        fsIdentifier = "uuid";

        # Libreboot already provides GRUB as the coreboot payload. NixOS only
        # needs to write a simple /boot/grub/grub.cfg for that payload to load.
        splashImage = lib.mkForce null;
        theme = lib.mkForce null;
        font = lib.mkForce null;
        gfxmodeBios = "text";
        gfxpayloadBios = "text";
        extraConfig = ''
          terminal_input console
          terminal_output console
        '';
      };
    };
  };
}
