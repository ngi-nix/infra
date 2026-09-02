{
  fileSystems = {
    "/" = {
      device = "rpool/root";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot0";
      fsType = "ext4";
    };
    "/postgres" = {
      device = "rpool/postgres";
      fsType = "zfs";
    };
  };

  # Yikes: "This is enabled by default for backwards compatibility purposes,
  # but it is highly recommended to disable this option, as it bypasses some of
  # the safeguards ZFS uses to protect your ZFS pools."
  boot.zfs.forceImportRoot = false;
}
