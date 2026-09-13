{ ... }:
{
  flake.nixosModules.laptop = {
    hardware = {
      bluetooth.enable = true;
      enableRedistributableFirmware = true;
    };

    powerManagement.enable = true;

    services = {
      fstrim.enable = true;
      fwupd.enable = true;
      hardware.bolt.enable = true;
      libinput.enable = true;
      thermald.enable = true;
      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 40;
        };
      };
      upower.enable = true;
    };

    zramSwap.enable = true;
  };
}
