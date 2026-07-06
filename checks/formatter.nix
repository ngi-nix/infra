{
  lib,
  pkgs,
  inputs,
  ...
}:
lib.makeExtensible (self: {
  treefmt = import inputs.treefmt-nix;
  config = {
    projectRootFile = "flake.nix";

    programs.actionlint.enable = true;
    programs.nixfmt.enable = true;
    programs.zizmor.enable = false;

    settings.formatter.editorconfig-checker = {
      command = pkgs.editorconfig-checker;
      includes = [ "*" ];
      priority = 9; # last
    };
  };

  eval = self.treefmt.evalModule pkgs self.config;
})
