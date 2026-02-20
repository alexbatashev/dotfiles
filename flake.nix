{
  description = "Alex's dotfiles managed with home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      mkHome = system: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { flakeRoot = self; };
          modules = [ ./home/alex.nix ] ++ extraModules;
        };
    in
    {
      # Usage:
      #   nix run home-manager -- switch --flake .#alex@linux
      #   nix run home-manager -- switch --flake .#alex@darwin
      homeConfigurations = {
        "alex@linux"  = mkHome "x86_64-linux"    [ ./home/profiles/linux-desktop.nix ];
        "alex@darwin" = mkHome "aarch64-darwin"  [ ./home/profiles/darwin.nix ];
      };
    };
}
