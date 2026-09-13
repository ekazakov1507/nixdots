{ ... }:
let
  diskConfig = import ./_disk-device.nix;
  commonMountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  flake.nixosModules.t480Disko = {
    boot.supportedFilesystems = [
      "btrfs"
      "ext4"
    ];

    disko.devices = {
      disk.main = {
        device = diskConfig.device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              type = "8300";
              size = "1G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
              };
            };

            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = commonMountOptions;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = commonMountOptions;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = commonMountOptions;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
