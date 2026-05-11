{ pkgs, lib, ... }:
{
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      nil
      nixd
      rust-analyzer
    ];
    settings = {
      theme = "darcula_fixed";
      editor = {
        cursorline = true;
        completion-replace = true;
        indent-guides = {
          render = true;
          skip-levels = 1;
        };
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };

        inline-diagnostics = {
          cursor-line = "warning";
          other-lines = "error";
        };

        statusline = {
          right = [
            "diagnostics"
            "spacer"
            "file-type"
            "file-encoding"
            "file-line-ending"
            "spacer"
            "selections"
            "register"
            "spacer"
            "position"
            "position-percentage"
            "total-line-numbers"
          ];
        };
      };
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt;
      }
      {
        name = "rust";
        auto-format = true;
        language-servers = [ "rust-analyzer" ];
        formatter.command = "rustfmt";
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
