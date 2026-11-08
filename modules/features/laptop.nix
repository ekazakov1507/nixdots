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
      power-profiles-daemon.enable = false;
      tlp = {
        enable = true;
        pd.enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 40;

          CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
          CPU_MIN_PERF_ON_SAV = 0;
          CPU_MAX_PERF_ON_SAV = 25;
        };
      };
      upower.enable = true;
    };

    zramSwap.enable = true;
  };
}
