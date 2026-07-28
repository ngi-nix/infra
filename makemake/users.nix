{ lib, pkgs, ... }:
let
  # To give yourself permission to use `makemake` as a remote builder, add
  # yourself to the list below (sorted appropriately). You'll need `remotebuild = true;`.
  #
  # Once your change is merged and deployed, you can verify you can access the
  # remote store with `nix store ping --store
  # ssh-ng://[username]@makemake.ngi.nixos.org`.
  users = {
    # keep-sorted start block=yes
    deploy = {
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4YrKRDO6sYByYY0TQS0IsxxGTiPv1caLVmAuryxzcZ github-actions"
      ];
    };
    eljamm = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8UxRGGl5Yty1zj41vNr1o8SDLUGrXHoRqx6RxuUnU9"
      ];
    };
    erethon = {
      remotebuild = true;
      wheel = true;
      keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPb9z1U7Sti2lls0mlcmyPwmwD91amKwVlLZHYclSoULAAAABHNzaDo="
      ];
    };
    hexa = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWQRR7dspgQ6kCwyFnoVlgmmPR4iWL1+nvq6a5ad2Ug hexa@gaia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSpdtIxIBFtd7TLrmIPmIu5uemAFJx4sNslRsJXfFxr hexa@helix"
      ];
    };
    imincik = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWlDZ4iZZAAxmlJknc55t71QfJRZqszgXraiyS6tVv1 ivan.mincik@gmail.com"
      ];
    };
    jfly = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIImw0Xc1buEQ9WOskyGGeg3QwdbU7DTUQBiu02fObDlm"
      ];
    };
    julm = {
      remotebuild = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1fy4gn9zYmCxuWjpC05OlJNK36X67HLbbcGqA1CN5R julm@nan2gua1"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGCGvxJhoThKVDRLf+D+eJtnF4MzHOvOYMV5QeSFGH+1 julm@pumpkin"
      ];
    };
    phanirithvij = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8/+FK1TAZV7p1a92/ykOXqPGt34rsiHxXLgVG3b/3x"
      ];
    };
    prince213 = {
      remotebuild = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3g6gsmSDqACwUoCtuDOMKyF4kp+xUWQFMmSGZBkh1K"
      ];
    };
    vcunat = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4IJkFIVyImkfD4fM89ya+hy2ig8kUg09PCdjB5rS82akFoucYZSYMG41ZrlMT5LAikIgWusBzpO5bBkqxqcYqaYK/VF06zVBk3kF1pAIoitst9z0PLXY8/N+bFJg6oT7p6EWGRvFggUviSTTvJFMNUdDgEpsLqLp8+IYXjfM3Cz6+TQmyWQSockobRqgdILTjc1p2uxmNSzy2fElpZ0sKRPLNYG4SVPBPnOavs1KPOtyC1pIHOuz5A605gPLFXoWpX2lIK6atmGheiHxURDAX3pANVm+iMmnjteP0jEGU26/SPqgVP3OxdcryHxL3WnSJGtTnycoa30qP/Edmy9vB"
      ];
    };
    zimbatm = {
      remotebuild = true;
      wheel = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuiDoBOxgyer8vGcfAIbE6TC4n4jo8lhG9l01iJ0bZz zimbatm"
      ];
    };
    # keep-sorted end
  };
in
{
  # Users in the remotebuild group are trusted.
  nix.settings.trusted-users = [ "@remotebuild" ];

  users = {
    mutableUsers = false;
    groups.remotebuild = { };

    # TODO: drop root access, instead force people to ssh as their specific user:
    # <https://github.com/ngi-nix/infra/issues/26>.
    users.root.openssh.authorizedKeys.keys = lib.pipe users [
      (lib.filterAttrs (name: user: user.wheel or false))
      (lib.mapAttrsToList (name: user: user.keys))
      lib.flatten
    ];

    # TODO: remove the remotebuild user once everyone is using personal accounts:
    # <https://github.com/ngi-nix/infra/issues/26>.
    users.remotebuild = {
      isNormalUser = true;
      createHome = false;
      group = "remotebuild";
      openssh.authorizedKeys.keys = lib.pipe users [
        (lib.filterAttrs (name: user: user.remotebuild or false))
        (lib.mapAttrsToList (name: user: user.keys))
        lib.flatten
      ];
    };
  };

  # TODO: clean up once everyone is using personal accounts:
  # <https://github.com/ngi-nix/infra/issues/26>.
  systemd.tmpfiles.rules =
    let
      rootBashProfile = pkgs.writeText "bash_profile" /* bash */ ''
        echo "" >&2
        echo "*** NOTE: SSH access as the root user is deprecated, and will be removed soon! ***" >&2
        echo "" >&2
        echo "Please switch to to your own personal user." >&2
        echo "See <https://github.com/ngi-nix/infra/issues/26> for details." >&2
      '';
      remoteBuildBashProfile = pkgs.writeText "bash_profile" /* bash */ ''
        echo "" >&2
        echo "*** NOTE: The remotebuild user is deprecated, and will be removed soon! ***" >&2
        echo "" >&2
        echo "Please switch to to your own personal user." >&2
        echo "See <https://github.com/ngi-nix/infra/issues/26> for details." >&2
      '';
    in
    [
      "L+ /root/.bash_profile 0644 root root - ${rootBashProfile}"
      "L+ /home/remotebuild/.bash_profile 0644 remotebuild remotebuild - ${remoteBuildBashProfile}"
    ];
}
