{
  description = "dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        username: extraModules: extraHome:
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
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs outputs username;
              };
              home-manager.users.${username} = {
                imports = [ ./home.nix ] ++ extraHome;
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
          modules = [ ./home.nix ] ++ extraModules;
        };
    in
    {
      darwinConfigurations = {
        "alex@macbook" =
          mkDarwin "alex"
            [ ./profiles/macbook.nix ]
            [ ./profiles/alex.nix ./profiles/gui.nix ./profiles/macos.nix ];
      };

      homeConfigurations = {
        "alex@desktop" = mkHome "x86_64-linux" "alex" [
          ./profiles/gui.nix
          ./profiles/desktop.nix
          ./profiles/alex.nix
        ];
        "alex@tower" = mkHome "x86_64-linux" "alex" [
          ./profiles/gui.nix
          ./profiles/omarchy.nix
          ./profiles/desktop.nix
          ./profiles/alex.nix
        ];
        "alex@orion" = mkHome "aarch64-linux" "alex" [
          ./profiles/orion.nix
          ./profiles/alex.nix
        ];
        "alex@nuc" = mkHome "x86_64-linux" "alex" [
          ./profiles/nuc.nix
          ./profiles/alex.nix
        ];
        "alex@nas" = mkHome "x86_64-linux" "alex" [
          ./profiles/alex.nix
        ];
      };
    };
}
