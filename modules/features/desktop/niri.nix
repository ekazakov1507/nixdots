{ ... }:
{
  flake.nixosModules.niriDesktop = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      useNautilus = true;
    };

    programs.uwsm = {
      enable = true;
      waylandCompositors.niri = {
        prettyName = "Niri";
        comment = "Niri compositor managed by UWSM";
        # Match the compositor path that UWSM itself recommends.
        binPath = "/run/current-system/sw/bin/niri";
      };
    };

    programs.dconf.enable = true;

    security.polkit.enable = true;

    services = {
      blueman.enable = true;
      gvfs.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      alacritty
      brightnessctl
      fuzzel
      libnotify
      playerctl
      pavucontrol
      swaybg
      swaylock
      waybar
      wev
      wl-clipboard
      wireplumber
      xwayland-satellite
    ];
  };
}
