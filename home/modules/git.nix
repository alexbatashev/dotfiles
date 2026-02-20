{ ... }:
{
  programs.git = {
    enable = true;

    userName  = "Alexander Batashev";
    userEmail = "alex@batashev.me";

    # SSH-based commit signing
    signing = {
      key        = "~/.ssh/id_ed25519";
      signByDefault = true;
    };

    # git-lfs filters
    lfs.enable = true;

    aliases = {
      # View abbreviated SHA, description, and history graph of the latest 20 commits
      l    = "log --pretty=oneline -n 20 --graph --abbrev-commit";
      s    = "status -s";
      credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";
      aliases = "config --get-regexp alias";
      contributors = "shortlog --summary --numbered";
      fc   = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short -S$1; }; f";
      fm   = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short --grep=$1; }; f";
      fpush = "push --force-with-lease";
    };

    extraConfig = {
      core = {
        autocrlf     = "input";
        preloadindex = true;
        fscache      = true;
        excludesfile = "~/dotfiles/.gitignore_default";
        trustctime   = false;
        whitespace   = "space-before-tab,-indent-with-non-tab,trailing-space";
        editor       = "hx";
      };
      diff."bin".textconv = "hexdump -v -C";
      merge = {
        log         = true;
        renamelimit = 3129;
      };
      gc.auto    = 256;
      gpg.format = "ssh";
      branch.sort = "-committerdate";
    };
  };
}
