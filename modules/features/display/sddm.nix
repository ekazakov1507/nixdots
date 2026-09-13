{ ... }:
{
  flake.nixosModules.sddmDisplay = { config, pkgs, ... }:
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
            --replace-fail "@loginScale@" "${toString visual.loginScale}"

          runHook postInstall
        '';
      };
    in
    {
      services.displayManager.defaultSession = "niri-uwsm";

      services.displayManager.sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        enableHidpi = true;
        autoNumlock = true;
        theme = themeName;

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
      ];
    };
}
