{ ... }:
{
  flake.nixosModules.sddmDisplay = { config, lib, pkgs, ... }:
    let
      themeName = "t480-noctalia";
      visual = config.t480.visualAccessibility;
      sddmTheme = pkgs.stdenvNoCC.mkDerivation {
        pname = "${themeName}-sddm-theme";
        version = "1.0.0";
        src = ./sddm-theme;

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p "$out/share/sddm/themes/${themeName}"
          cp -r . "$out/share/sddm/themes/${themeName}/"
          substituteInPlace "$out/share/sddm/themes/${themeName}/theme.conf" \
            --replace-fail "@loginScale@" "${toString visual.loginScale}" \
            --replace-fail "@backgroundImage@" ${lib.escapeShellArg (if config.t480.sddmWallpaper == null then "" else toString (builtins.path { path = config.t480.sddmWallpaper; name = "sddm-wallpaper"; }))}

          runHook postInstall
        '';
      };
    in
    {
      options.t480.sddmWallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Optional SDDM wallpaper, independent from the desktop wallpaper.";
      };

      config = {
      services.displayManager.defaultSession = "niri-uwsm";

      systemd.services.display-manager.environment = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = toString visual.cursorSize;
      };

      services.displayManager.sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        enableHidpi = true;
        autoNumlock = true;
        theme = themeName;
        settings.Theme.CursorTheme = "Adwaita";
        settings.Theme.CursorSize = visual.cursorSize;

        wayland = {
          enable = true;
          compositor = "weston";
        };

        extraPackages = [
          sddmTheme
        ];
      };

      environment.systemPackages = [
        sddmTheme
        pkgs.adwaita-icon-theme
      ];
      };
    };
}
