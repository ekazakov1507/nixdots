{ inputs, self, ... }:
{
  flake.nixosModules.t480Configuration = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480

      self.nixosModules.base
      self.nixosModules.accessibility
      self.nixosModules.librebootGrub
      self.nixosModules.laptop
      self.nixosModules.lazyvim
      self.nixosModules.noctaliaShell
      self.nixosModules.niriDesktop
      self.nixosModules.sddmDisplay
      self.nixosModules.user
      self.nixosModules.t480Disko
      self.nixosModules.t480Hardware
    ];

    networking.hostName = "t480";
    system.stateVersion = "26.05";
  };
}
