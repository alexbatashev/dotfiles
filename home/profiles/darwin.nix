{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # macOS-specific extras
    # (iTerm2 / Docker Desktop are managed outside nix on macOS)
  ];

  # macOS puts fonts in ~/Library/Fonts
  home.file."Library/Fonts".source = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts";
}
