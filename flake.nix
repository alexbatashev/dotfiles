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

    zed.url = "github:zed-industries/zed";
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    claude-code.url = "github:sadjow/claude-code-nix";
    nixgl.url = "github:nix-community/nixGL";
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
      claude-code,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      nixpkgsConfig = {
        allowUnfree = true;
      };

      mkDarwin =
        username: extraModules:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs outputs username;
            darwinModules = "${self}/modules/darwin";
          };
          modules = [
            { nixpkgs.config = nixpkgsConfig; }
            inputs.home-manager.darwinModules.home-manager
            {
              nixpkgs.overlays = [ claude-code.overlays.default ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs outputs username;
              };
              home-manager.users.${username} = {
                imports = [ ./home.nix ];
              };
            }
          ]
          ++ extraModules;
        };

      mkHome =
        system: username: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          };
          extraSpecialArgs = {
            inherit
              inputs
              outputs
              username
              ;
          };
          modules = [
            {
              nixpkgs.overlays = [ claude-code.overlays.default ];
            }
            ./home.nix
          ]
          ++ extraModules;
        };
    in
    {
      darwinConfigurations = {
        "alex@macbook" = mkDarwin "alex" [
          ./profiles/macbook.nix
          ./profiles/alex.nix
        ];
      };

      homeConfigurations = {
        "alex@desktop" = mkHome "x86_64-linux" "alex" [
          ./profiles/desktop.nix
          ./profiles/alex.nix
        ];
        "alex@orion" = mkHome "aarch64-linux" "alex" [
          ./profiles/alex.nix
        ];
      };
    };
}
