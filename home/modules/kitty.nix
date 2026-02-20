{ ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 18;
    };

    settings = {
      copy_on_select         = true;
      url_style              = "single";
      open_url_with          = "default";
      remember_window_size   = true;
      initial_window_width   = 640;
      initial_window_height  = 400;
      macos_option_as_alt    = true;
    };

    # Pull in the vscode-dark theme (file is linked separately below)
    extraConfig = "include vscode-dark.conf";
  };

  # Ship the bundled theme files alongside the generated kitty.conf
  xdg.configFile."kitty/vscode-dark.conf".source = ../../kitty/.config/kitty/vscode-dark.conf;
  xdg.configFile."kitty/nord.conf".source         = ../../kitty/.config/kitty/nord.conf;
}
