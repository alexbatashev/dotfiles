{ pkgs, lib, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "darcula_fixed";
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
      darcula_fixed = {
        "inherits" = "darcula";
        "ui.background" = { };
        "ui.gutter" = { };
        "ui.linenr" = { };
      };
    };
  };
}
