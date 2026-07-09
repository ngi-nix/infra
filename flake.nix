{
  description = "ngi-nix infrastructure";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.buildbot-nix.inputs.treefmt-nix.follows = "treefmt-nix";
  inputs.buildbot-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.buildbot-nix.url = "github:nix-community/buildbot-nix";
  inputs.systems.url = "github:nix-systems/default-linux";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      supportedSystems = import inputs.systems;
      eachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;
      treefmtEvals = eachSupportedSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        (pkgs.callPackage ./checks/formatter.nix { inherit inputs; }).eval
      );
    in
    {
      formatter = eachSupportedSystem (system: treefmtEvals.${system}.config.build.wrapper);

      checks = eachSupportedSystem (
        system:
        let
          treefmtEval = treefmtEvals.${system};
        in
        {
          formatting = treefmtEval.config.build.check self;
          "nixos/makemake" = self.nixosConfigurations.makemake.config.system.build.toplevel;
        }
      );

      nixosConfigurations.makemake = import makemake/default.nix { inherit inputs; };

      devShells = eachSupportedSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.sops
              treefmtEvals.${system}.config.build.wrapper
            ];
          };
        }
      );
    };
}
