{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "rust"
      "jellybeans-vim"
    ];
    userSettings = {
      theme = {
        mode = "system";
        dark = "Jellybeans";
        light = "One Light";
      };
      hour_format = "hour24";
      vim_mode = true;
      helix_mode = true;
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_font_size = 20;
      ui_font_size = 18;

      terminal = {
        alternate_scroll = "off";
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";
        option_as_meta = false;
        button = false;
        shell = "system";
        toolbar = {
          title = true;
        };
        working_directory = "current_project_directory";

        detect_venv = {
          on = {
            directories = [
              ".env"
              "env"
              ".venv"
              "venv"
            ];
            activate_script = "default";
          };
        };
      };
      lsp = {
        rust-analyzer = {
          binary = {
            path_lookup = true;
          };
        };

        nix = {
          binary = {
            path_lookup = true;
          };
        };
      };
    };
  };
}
