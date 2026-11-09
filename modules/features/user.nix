{ ... }:
{
  flake.nixosModules.user = { config, pkgs, ... }:
    let
      username = "user";
      visual = config.t480.visualAccessibility;
    in
    {
      users.mutableUsers = true;

      users.users.${username} = {
        isNormalUser = true;
        description = "T480 User";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.${username} = {
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "26.05";

        home.packages = with pkgs; [
          git
          htop
        ];

        xdg.enable = true;

        dconf.settings."org/gnome/desktop/interface" = {
          text-scaling-factor = visual.gtkTextScale;
          cursor-size = visual.cursorSize;
        };

        xdg.configFile."alacritty/alacritty.toml".text = ''
          [font]
          size = 16.0
        '';

        xdg.configFile."niri/config.kdl".text = ''
          input {
              keyboard {
                  numlock
                  xkb {
                      layout "us,ru"
                      options "grp:alt_shift_toggle,ctrl:swap_lctl_lcap"
                  }
              }

              touchpad {
                  tap
                  dwt
                  natural-scroll
              }
          }

          output "${visual.outputName}" {
              scale ${toString visual.outputScale}
          }

          cursor {
              xcursor-size ${toString visual.cursorSize}
          }

          layout {
              gaps 16
              center-focused-column "never"
              background-color "transparent"

              default-column-width { proportion 1.0; }

              focus-ring {
                  width ${toString visual.focusRingWidth}
                  active-color "${visual.focusRingActiveColor}"
                  inactive-color "${visual.focusRingInactiveColor}"
              }
          }

          overview {
              workspace-shadow {
                  off
              }
          }

          hotkey-overlay {
              skip-at-startup
              hide-not-bound
          }

          window-rule {
              geometry-corner-radius 20
              clip-to-geometry true
          }

          layer-rule {
              match namespace="^noctalia-wallpaper"
              place-within-backdrop true
          }

          debug {
              honor-xdg-activation-with-invalid-serial
          }

          spawn-at-startup "uwsm" "app" "--" "noctalia"

          prefer-no-csd
          screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

          xwayland-satellite {
              path "xwayland-satellite"
          }

          binds {
              Mod+Shift+Slash { show-hotkey-overlay; }

              Mod+T hotkey-overlay-title="Open terminal" { spawn "alacritty"; }
              Mod+Ctrl+Minus { spawn "niri" "msg" "output" "${visual.outputName}" "scale" "1"; }
              Mod+Ctrl+0 { spawn "niri" "msg" "output" "${visual.outputName}" "scale" "${toString visual.outputScale}"; }
              Mod+Ctrl+Equal { spawn "niri" "msg" "output" "${visual.outputName}" "scale" "1.5"; }
              Mod+Space hotkey-overlay-title="Open launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
              Mod+D hotkey-overlay-title="Open launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
              Mod+S hotkey-overlay-title="Open control center" { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
              Mod+Comma hotkey-overlay-title="Open settings" { spawn "noctalia" "msg" "settings-toggle"; }
              Mod+V hotkey-overlay-title="Open clipboard" { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }
              Mod+C hotkey-overlay-title="Open calculator" { spawn "noctalia" "msg" "panel-toggle" "launcher" "/calc"; }
              Super+Alt+L hotkey-overlay-title="Lock screen" { spawn "noctalia" "msg" "session" "lock"; }

              XF86AudioRaiseVolume allow-when-locked=true {
                  spawn "noctalia" "msg" "volume-up";
              }
              XF86AudioLowerVolume allow-when-locked=true {
                  spawn "noctalia" "msg" "volume-down";
              }
              XF86AudioMute allow-when-locked=true {
                  spawn "noctalia" "msg" "volume-mute";
              }
              XF86AudioMicMute allow-when-locked=true {
                  spawn "noctalia" "msg" "mic-mute";
              }

              XF86AudioPlay allow-when-locked=true { spawn "noctalia" "msg" "media" "toggle"; }
              XF86AudioStop allow-when-locked=true { spawn "noctalia" "msg" "media" "stop"; }
              XF86AudioPrev allow-when-locked=true { spawn "noctalia" "msg" "media" "previous"; }
              XF86AudioNext allow-when-locked=true { spawn "noctalia" "msg" "media" "next"; }

              XF86MonBrightnessUp allow-when-locked=true {
                  spawn "noctalia" "msg" "brightness-up";
              }
              XF86MonBrightnessDown allow-when-locked=true {
                  spawn "noctalia" "msg" "brightness-down";
              }

              Mod+O repeat=false { toggle-overview; }
              Mod+Q repeat=false { close-window; }

              Mod+Left { focus-column-left; }
              Mod+Down { focus-window-down; }
              Mod+Up { focus-window-up; }
              Mod+Right { focus-column-right; }
              Mod+H { focus-column-left; }
              Mod+J { focus-window-down; }
              Mod+K { focus-window-up; }
              Mod+L { focus-column-right; }

              Mod+Ctrl+Left { move-column-left; }
              Mod+Ctrl+Down { move-window-down; }
              Mod+Ctrl+Up { move-window-up; }
              Mod+Ctrl+Right { move-column-right; }
              Mod+Ctrl+H { move-column-left; }
              Mod+Ctrl+J { move-window-down; }
              Mod+Ctrl+K { move-window-up; }
              Mod+Ctrl+L { move-column-right; }

              Mod+1 { focus-workspace 1; }
              Mod+2 { focus-workspace 2; }
              Mod+3 { focus-workspace 3; }
              Mod+4 { focus-workspace 4; }
              Mod+5 { focus-workspace 5; }
              Mod+6 { focus-workspace 6; }
              Mod+7 { focus-workspace 7; }
              Mod+8 { focus-workspace 8; }
              Mod+9 { focus-workspace 9; }

              Mod+Ctrl+1 { move-column-to-workspace 1; }
              Mod+Ctrl+2 { move-column-to-workspace 2; }
              Mod+Ctrl+3 { move-column-to-workspace 3; }
              Mod+Ctrl+4 { move-column-to-workspace 4; }
              Mod+Ctrl+5 { move-column-to-workspace 5; }
              Mod+Ctrl+6 { move-column-to-workspace 6; }
              Mod+Ctrl+7 { move-column-to-workspace 7; }
              Mod+Ctrl+8 { move-column-to-workspace 8; }
              Mod+Ctrl+9 { move-column-to-workspace 9; }

              Print { screenshot; }
              Ctrl+Print { screenshot-screen; }
              Alt+Print { screenshot-window; }

              Mod+Shift+E repeat=false { spawn "noctalia" "msg" "session" "logout"; }
          }
        '';

        xdg.configFile."waybar/config.jsonc".text = ''
          {
            "layer": "top",
            "position": "top",
            "height": 34,
            "spacing": 8,
            "margin-top": 8,
            "margin-left": 10,
            "margin-right": 10,
            "modules-left": [
              "niri/workspaces"
            ],
            "modules-center": [
              "niri/window"
            ],
            "modules-right": [
              "tray",
              "network",
              "pulseaudio",
              "battery",
              "battery#bat0",
              "battery#bat1",
              "clock"
            ],
            "niri/workspaces": {
              "format": "{icon}",
              "format-icons": {
                "active": "[*]",
                "default": "[ ]"
              }
            },
            "niri/window": {
              "format": "{}",
              "icon": false,
              "separate-outputs": true,
              "max-length": 70
            },
            "tray": {
              "spacing": 10
            },
            "network": {
              "format-wifi": "NET {essid} {signalStrength}%",
              "format-ethernet": "NET wired",
              "format-disconnected": "NET down",
              "tooltip-format": "{ifname}"
            },
            "pulseaudio": {
              "format": "VOL {volume}%",
              "format-muted": "VOL mute",
              "scroll-step": 5
            },
            "battery": {
              "interval": 10,
              "states": {
                "warning": 30,
                "critical": 15
              },
              "format": "TOT {capacity}%",
              "format-charging": "TOT {capacity}% +",
              "format-plugged": "TOT {capacity}% AC",
              "format-full": "TOT full",
              "tooltip-format": "Total {capacity}% {time}"
            },
            "battery#bat0": {
              "bat": "BAT0",
              "interval": 10,
              "states": {
                "warning": 30,
                "critical": 15
              },
              "format": "BAT0 {capacity}%",
              "format-charging": "BAT0 {capacity}% +",
              "format-plugged": "BAT0 {capacity}% AC",
              "format-full": "BAT0 full",
              "tooltip-format": "BAT0 {capacity}% {time}"
            },
            "battery#bat1": {
              "bat": "BAT1",
              "interval": 10,
              "states": {
                "warning": 30,
                "critical": 15
              },
              "format": "BAT1 {capacity}%",
              "format-charging": "BAT1 {capacity}% +",
              "format-plugged": "BAT1 {capacity}% AC",
              "format-full": "BAT1 full",
              "tooltip-format": "BAT1 {capacity}% {time}"
            },
            "clock": {
              "format": "{:%a %d %b  %H:%M}"
            }
          }
        '';

        xdg.configFile."waybar/style.css".text = ''
          * {
            border: none;
            border-radius: 0;
            font-family: sans-serif;
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background: rgba(20, 24, 28, 0.92);
            color: #e6edf3;
          }

          #workspaces,
          #window,
          #tray,
          #network,
          #pulseaudio,
          #battery,
          #clock {
            background: #1f252c;
            border-radius: 10px;
            margin: 6px 0;
            padding: 4px 10px;
          }

          #workspaces button {
            color: #8b949e;
            padding: 0 6px;
          }

          #workspaces button.active,
          #workspaces button.focused {
            color: #f0f6fc;
          }

          #window {
            color: #9bd1ff;
          }

          #battery.warning {
            color: #f7b955;
          }

          #battery.critical {
            color: #ff7b72;
          }

          #battery.charging,
          #battery.plugged {
            color: #7ee787;
          }
        '';

        programs.bash.enable = true;
        programs.git.enable = true;
        programs.home-manager.enable = true;
      };
    };
}
