{ lib, pkgs, ... }:
{
  # Users in the remotebuild group are trusted.
  nix.settings.trusted-users = [ "@remotebuild" ];

  users =
    let
      keys = lib.mapAttrs (name: value: ./keys/${name}) (builtins.readDir ./keys);
      deploy = with keys; [ github-actions ];
      infra = with keys; [
        hexa-gaia
        hexa-helix
        vcunat
        zimbatm
      ];
      ngi = with keys; [
        erethon
        imincik
        jfly
        eljamm
        phanirithvij-iron
      ];
      remotebuild = with keys; [
        julm
        prince213
      ];
    in
    {
      mutableUsers = false;
      groups.remotebuild = { };

      # TODO: drop root access, instead force people to ssh as their specific user:
      # <https://github.com/ngi-nix/infra/issues/26>.
      users.root.openssh.authorizedKeys.keyFiles = deploy ++ infra ++ ngi;

      # TODO: remove the remotebuild user once everyone is using personal accounts:
      # <https://github.com/ngi-nix/infra/issues/26>.
      users.remotebuild = {
        isNormalUser = true;
        createHome = false;
        group = "remotebuild";
        openssh.authorizedKeys.keyFiles = infra ++ ngi ++ remotebuild;
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
