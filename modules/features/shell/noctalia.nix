{ inputs, ... }:
{
  flake.nixosModules.noctaliaShell = { config, pkgs, ... }:
    let
      # Keep this in sync with modules/features/user.nix until user settings are centralized.
      username = "user";
      noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      visual = config.t480.visualAccessibility;
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

        programs.noctalia = {
          enable = true;
          package = noctaliaPackage;
          systemd.enable = false;
          checkConfig = true;

          settings = {
            shell = {
              font_family = "sans-serif";
              settings_show_advanced = true;
              polkit_agent = true;
            };

            accessibility = {
              ui_scale = visual.shellUiScale;
              high_contrast = visual.highContrast;
            };

            bar = {
              order = [ "default" ];

              default = {
                position = "top";
                capsule = false;
                scale = visual.barScale;
                font_scale = visual.barFontScale;
                start = [ "launcher" "active-window" ];
                center = [ "workspaces" ];
                end = [
                  "tray"
                  "notifications"
                  "battery_label_internal"
                  "battery_internal"
                  "battery_label_external"
                  "battery_external"
                  "power_profile"
                  "volume"
                  "brightness"
                  "control-center"
                  "clock"
                ];
              };
            };

            widget = {
              battery_label_internal = {
                type = "text";
                text = "BAT0";
              };
              battery_internal = {
                type = "battery";
                device = "BAT0";
                display_mode = "glyph";
                show_label = true;
                label_content = "percent";
                hide_when_plugged = false;
                hide_when_full = false;
              };
              battery_label_external = {
                type = "text";
                text = "BAT1";
              };
              battery_external = {
                type = "battery";
                device = "BAT1";
                display_mode = "glyph";
                show_label = true;
                label_content = "percent";
                hide_when_plugged = false;
                hide_when_full = false;
              };
            };
          };
        };
      };
    };
}
