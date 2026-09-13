{ inputs, self, ... }:
{
  flake.nixosConfigurations.t480 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs self;
    };
    modules = [
      self.nixosModules.t480Configuration
    ];
  };
}
