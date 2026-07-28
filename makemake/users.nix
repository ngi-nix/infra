{ lib, ... }:
{
  # The remotebuild user is trusted.
  nix.settings.trusted-users = [ "remotebuild" ];

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
      users.root.openssh.authorizedKeys.keyFiles = deploy ++ infra ++ ngi;
      users.remotebuild = {
        isNormalUser = true;
        createHome = false;
        group = "remotebuild";
        openssh.authorizedKeys.keyFiles = infra ++ ngi ++ remotebuild;
      };
      groups.remotebuild = { };
    };
}
