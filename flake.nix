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

    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Hosts are described on two axes. `os/` says what the operating system
  # already provides, `hosts/` says what the machine needs on top. Omarchy
  # ships its own curated tool set, so nix installs only the gaps there; Ubuntu
  # and macOS get everything from nix.
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

      username = "alex";

      nixpkgsConfig = {
        allowUnfree = true;
        nvidia.acceptLicense = true;
      };

      specialArgs = {
        inherit inputs outputs username;
      };

      mkDarwin =
        hostModule: homeModules:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          inherit specialArgs;
          modules = [
            { nixpkgs.config = nixpkgsConfig; }
            hostModule
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${username}.imports = [ ./home.nix ] ++ homeModules;
            }
          ];
        };

      mkHome =
        system: osModule: hostModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          };
          extraSpecialArgs = specialArgs;
          modules = [
            ./home.nix
            osModule
          ]
          ++ hostModules;
        };
    in
    {
      darwinConfigurations = {
        "alex@macbook" = mkDarwin ./hosts/macbook.nix [
          ./os/macos.nix
          ./modules/gui.nix
        ];
      };

      homeConfigurations = {
        "alex@desktop" = mkHome "x86_64-linux" ./os/omarchy.nix [ ./hosts/desktop.nix ];
        "alex@tower" = mkHome "x86_64-linux" ./os/omarchy.nix [ ./hosts/tower.nix ];
        "alex@nuc" = mkHome "x86_64-linux" ./os/ubuntu.nix [ ./hosts/nuc.nix ];
        "alex@orion" = mkHome "aarch64-linux" ./os/ubuntu.nix [ ./hosts/orion.nix ];
      };
    };
}
