{ config, pkgs, ... }:

{
  options = {};

  config = {
    boot.kernelModules = [ "zram" ];

    boot.extraModprobeConfig = ''
      options zram num_devices=1
    '';

    systemd.services.zram0-setup = {
      description = "Setup zram0 swap";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "zram-setup" ''
          echo zstd > /sys/block/zram0/comp_algorithm
          echo $((4 * 1024 * 1024 * 1024)) > /sys/block/zram0/disksize
          ${pkgs.util-linux}/bin/mkswap /dev/zram0
          ${pkgs.util-linux}/bin/swapon /dev/zram0 -p 100
        '';
        ExecStop = pkgs.writeShellScript "zram-teardown" ''
          ${pkgs.util-linux}/bin/swapoff /dev/zram0
        '';
      };
    };
  };
}
