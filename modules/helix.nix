{pkgs, lib, ...}:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "jellybeans_fixed";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
      }
      {
        name = "rust";
        auto-format = true;
      }
    ];

    themes = {
      jellybeans_fixed = {
        "inherits" = "jellybeans";
        "ui.background" = { };
      };
    };
  };
}
