{ self, ... }:
{
  perSystem = { pkgs, ... }:
    let
      host = self.nixosConfigurations.t480.config;
      home = host.home-manager.users.user;
      niriConfig = pkgs.writeText "t480-niri.kdl" home.xdg.configFile."niri/config.kdl".text;
    in
    {
      checks = {
        installer = pkgs.runCommand "t480-installer-checks" {
          nativeBuildInputs = [ pkgs.bash pkgs.shellcheck ];
        } ''
          shellcheck --source-path=SCRIPTDIR ${self}/scripts/live-install-t480.sh ${self}/tests/installer.sh
          bash ${self}/tests/installer.sh ${self}/scripts/live-install-t480.sh
          touch "$out"
        '';

        niri-config = pkgs.runCommand "t480-niri-config-check" {
          nativeBuildInputs = [ host.programs.niri.package ];
        } ''
          niri validate --config ${niriConfig}
          touch "$out"
        '';

        # The Home Manager source is built using Noctalia's config validator.
        noctalia-config = pkgs.runCommand "t480-noctalia-config-check" { } ''
          cp ${home.xdg.configFile."noctalia/config.toml".source} "$out"
        '';

        t480 = host.system.build.toplevel;
      };
    };
}
