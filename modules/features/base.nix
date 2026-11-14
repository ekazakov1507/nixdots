{ ... }:
{
  flake.nixosModules.base = { pkgs, ... }: {
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    time.timeZone = "Europe/Moscow";

    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle,ctrl:swap_lctl_lcap";
    };
    console.useXkbConfig = true;

    networking.firewall.enable = true;
    networking.networkmanager.enable = true;

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    programs.git.enable = true;
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    environment.systemPackages = with pkgs; [
      curl
      git
      htop
      pciutils
      usbutils
      vim
      wget
    ];
  };
}
