{ pkgs, ... }:
{
  programs.git = {
    enable = true;

    # SSH-based commit signing
    signing = {
      key = if pkgs.stdenv.isDarwin then "~/.ssh/id_ecdsa" else "~/.ssh/id_ed25519";
      signByDefault = true;
    };

    lfs.enable = true;

    settings = {
      user = {
        name = "Alexander Batashev";
        email = "alex@batashev.me";
      };

      alias = {
        # View abbreviated SHA, description, and history graph of the latest 20 commits
        l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
        s = "status -s";
        credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";
        aliases = "config --get-regexp alias";
        contributors = "shortlog --summary --numbered";
        fc = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short -S$1; }; f";
        fm = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short --grep=$1; }; f";
        fpush = "push --force-with-lease";
      };

      core = {
        autocrlf = "input";
        preloadindex = true;
        fscache = true;
        excludesfile = "~/dotfiles/.gitignore_default";
        trustctime = false;
        whitespace = "space-before-tab,-indent-with-non-tab,trailing-space";
        editor = "hx";
      };

      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = "true";
        "bin".textconv = "hexdump -v -C";
      };

      commit.verbose = true;
      column.ui = "auto";

      rerere = {
        enabled = true;
        autoupdate = true;
      };

      merge = {
        log = true;
        renamelimit = 3129;
      };

      pull.rebase = true;
      push.autoSetupRemote = true;

      gc.auto = 256;
      gpg.format = "ssh";
      branch.sort = "-committerdate";
    };
  };
}
