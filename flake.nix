{
  description = "dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Nix Darwin (for MacOS machines)
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, darwin, home-manager, nixpkgs, ... }@inputs:
  let
    inherit (self) outputs;

    nixpkgsConfig = {
      allowUnfree = true;
    };

    mkDarwin =
      username:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs username;
          darwinModules = "${self}/modules/darwin";
        };
        modules = [
          { nixpkgs.config = nixpkgsConfig; }
          ./platform/darwin.nix
        ];
      };

    mkHome =
      system: username:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config = nixpkgsConfig; 
        };
        extraSpecialArgs = {
          inherit inputs outputs username;
        };
        modules = [
          ./home.nix
        ];
      };
  in
  {
    darwinConfigurations = {
      "alex" = mkDarwin "alex";
    };

    homeConfigurations = {
      "alex@darwin" = mkHome "aarch64-darwin" "alex";
      "alex@linux" = mkHome "x86_64-linux" "alex";
      "alex@linux-arm" = mkHome "aarch64-linux" "alex";
    };
  };
}
