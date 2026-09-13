{ inputs, ... }:
{
  flake.nixosModules.noctaliaShell = { pkgs, ... }:
    let
      # Keep this in sync with modules/features/user.nix until user settings are centralized.
      username = "user";
      pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
      noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.niri."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };

      home-manager.users.${username} = {
        imports = [ inputs.noctalia.homeModules.default ];

        home.packages = with pkgs; [
          cliphist
          imagemagick
          python3
          wlsunset
        ];

        programs.noctalia-shell = {
          enable = true;
          package = noctaliaPackage;

          settings = {
            settingsVersion = 0;

            bar = {
              density = "compact";
              position = "top";
              showCapsule = false;

              widgets = {
                left = [
                  {
                    id = "Launcher";
                  }
                  {
                    id = "ActiveWindow";
                  }
                ];

                center = [
                  {
                    id = "Workspace";
                    hideUnoccupied = false;
                    labelMode = "none";
                  }
                ];

                right = [
                  {
                    id = "Tray";
                  }
                  {
                    id = "NotificationHistory";
                  }
                  {
                    id = "Battery";
                    alwaysShowPercentage = true;
                    warningThreshold = 30;
                  }
                  {
                    id = "Volume";
                  }
                  {
                    id = "Brightness";
                  }
                  {
                    id = "ControlCenter";
                  }
                  {
                    id = "Clock";
                    formatHorizontal = "HH:mm";
                    formatVertical = "HH mm";
                    useMonospacedFont = true;
                  }
                ];
              };
            };
          };

          plugins = {
            sources = [
              {
                enabled = true;
                name = "Official Noctalia Plugins";
                url = pluginSource;
              }
            ];

            states."niri-overview-launcher" = {
              enabled = true;
              sourceUrl = pluginSource;
            };

            version = 2;
          };
        };
      };
    };
}
