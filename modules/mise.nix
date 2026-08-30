{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Tools that ship faster than a nixpkgs bump is worth paying for: nix declares
  # the set, mise owns the binaries. "latest" resolves at install time rather
  # than pinning, so `mise up` upgrades without rewriting the read-only fragment
  # generated from globalConfig. Individual tools are declared by the module
  # that cares about them.
  #
  # Omarchy provides mise and declares these tools itself, through
  # ~/.local/bin wrappers that run `mise use -g` on every launch. Declaring them
  # here as well would give one mise config two writers, so nix stays out of it
  # entirely there.
  config = lib.mkIf (!config.os.shipsUserTools) {
    programs.mise = {
      enable = true;
      package = pkgs.mise;
      enableMutableConfig = true;

      globalConfig.tools.gh = "latest";
    };

    # `mise activate` only extends PATH for interactive shells. The shims
    # directory is what makes these binaries resolvable from non-interactive
    # callers too, such as git running gh as its credential helper.
    home.sessionPath = [ "${config.xdg.dataHome}/mise/shims" ];
  };
}
