{
  pkgs,
  config,
  lib,
  ...
}:

let
  # Unstable bump needed for `-expire-sites` feature
  git-pages' = pkgs.git-pages.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = "0.9.1-unstable-2026-08-27";
      src =
        (pkgs.fetchFromCodeberg {
          owner = "git-pages";
          repo = "git-pages";
          rev = "017649481612cfe12b6127ac8cac3afdcd7ab796";
          hash = "sha256-QUtWbPQzyiRN1wSlekoly4H8cTKvUP/egLAc+mBQOk8=";
        })
        // {
          tag = "0.9.1-unstable-2026-08-27";
        };
      vendorHash = "sha256-RKn3DxX/cJoR6cXkmR9UzwF9k67NZiGt9MKba178jBU=";
      ldflags = [
        "-s"
        "-X main.versionOverride=01764948"
      ];
      doInstallCheck = false;
      meta = previousAttrs.meta // {
        changelog = "";
      };
    }
  );
in
{
  system.services.git-pages = {
    # NOTE: to pass pkgs to git-pages-service.nix as an argument
    _module.args.pkgs = pkgs;
    imports = [ ./git-pages-service.nix ];
    git-pages = {
      package = git-pages';
      settings.server = {
        pages = "tcp/0.0.0.0:4000";
        caddy = "-";
        metrics = "tcp/0.0.0.0:4002";
      };
      cleanupInterval = "weekly";

      # NOTE: git-pages does need a password
      # it checks whether the hash computed from
      # the password set in the auth header in http requests
      # matches the hash in dns challenge txt record
      #secretsFile = sops template
    };
  };

  # Workaround needed until https://github.com/NixOS/nixpkgs/pull/554366 has landed
  systemd.timers.git-pages-expire = config.system.services.git-pages.systemd.timers.expire;
}
