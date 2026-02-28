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

  nixConfig = {
    extra-substituters = [
      "https://zed.cachix.org"
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  outputs =
    {
      self,
      darwin,
      home-manager,
      nixpkgs,
      ...
    }@inputs:
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
            inputs.home-manager.darwinModules.home-manager
            {
              # nixpkgs = nixpkgsConfig;

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs outputs username;
              };
              home-manager.users.${username} = {
                imports = [ ./home.nix ];
              };
            }
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
