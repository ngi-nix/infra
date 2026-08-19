{ pkgs, ... }:

{
  system.services.git-pages = {
    _module.args.pkgs = pkgs;
    imports = [ ./git-pages-service.nix ];
    git-pages = {
      package = pkgs.git-pages;
      port = 4000;
      caddyPort = null;
      metricsPort = 4002;
      # NOTE: git-pages does need a password
      # it checks whether the hash computed from
      # the password set in the auth header in http requests
      # matches the hash in dns challenge txt record
      #secretsFile = sops template
    };
  };
}
