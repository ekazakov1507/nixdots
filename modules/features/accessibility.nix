{ ... }:
{
  flake.nixosModules.accessibility = { lib, ... }:
    with lib;
    {
      options.t480.visualAccessibility = {
        outputName = mkOption {
          type = types.str;
          default = "eDP-1";
          description = "Connector name for the built-in display.";
        };

        outputScale = mkOption {
          type = types.float;
          default = 1.25;
          description = "Persistent scale for the built-in display.";
        };

        shellUiScale = mkOption {
          type = types.float;
          default = 1.25;
          description = "Scale for Noctalia panels and other shell surfaces.";
        };

        barScale = mkOption {
          type = types.float;
          default = 1.25;
          description = "Scale for Noctalia bar icons, padding, and controls.";
        };

        barFontScale = mkOption {
          type = types.float;
          default = 1.2;
          description = "Additional text scale for the Noctalia bar.";
        };

        gtkTextScale = mkOption {
          type = types.float;
          default = 1.25;
          description = "Text scale for GTK applications.";
        };

        cursorSize = mkOption {
          type = types.ints.positive;
          default = 48;
          description = "Cursor size in pixels.";
        };

        focusRingWidth = mkOption {
          type = types.ints.positive;
          default = 7;
          description = "Niri keyboard-focus ring width in logical pixels.";
        };

        focusRingActiveColor = mkOption {
          type = types.str;
          default = "#ffdf6c";
          description = "High-visibility colour for the focused Niri window.";
        };

        focusRingInactiveColor = mkOption {
          type = types.str;
          default = "#9aa4ad";
          description = "Colour for unfocused Niri windows.";
        };

        loginScale = mkOption {
          type = types.float;
          default = 1.25;
          description = "Scale multiplier for the SDDM login interface.";
        };

        highContrast = mkOption {
          type = types.bool;
          default = true;
          description = "Use high-contrast shell styling where it is supported.";
        };
      };
    };
}
