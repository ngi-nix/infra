{
  pkgs,
  config,
  ...
}:

let
  # Unstable bump needed for `-expire-sites` feature
  # TODO bump when new release is available from nixpkgs
  git-pages' = pkgs.git-pages.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = "0.9.1-unstable-2026-09-03";
      src =
        (pkgs.fetchFromCodeberg {
          owner = "git-pages";
          repo = "git-pages";
          rev = "507e57edbcfc0ec933a877bf26b1756ca0a61870";
          hash = "sha256-H5Fa3zhJ17Mx6ubmkhpajXQjj1CP2XRHoegjjloe9b0=";
        })
        // {
          tag = "0.9.1-unstable-2026-09-03";
        };
      vendorHash = "sha256-RKn3DxX/cJoR6cXkmR9UzwF9k67NZiGt9MKba178jBU=";
      ldflags = [
        "-s"
        "-X main.versionOverride=507e57ed"
      ];
      doInstallCheck = false;
      patches = (previousAttrs.patches or [ ]) ++ [
        # NOTE: this patch was deemed a HACK not a proper fix, https://github.com/ngi-nix/infra/issues/65#issuecomment-5533062649
        # Using this Hack while the proper fix is made.
        ./0001-feat-add-allow-retroactive-expiration-limit-config.patch
      ];
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
      settings.limits.allow-retroactive-expiration = true;
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
