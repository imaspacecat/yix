{ pkgs, host, ... }:

let
  cpd-script = pkgs.writeShellApplication {
    name = "cpd";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      xclip
    ];
    text = builtins.readFile ../script/cpd;
  };
in
{
  home.packages = [ cpd-script ];

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      gstat = "printf '\\033[1mStaged changes:\\033[0m\\n'; git diff --staged --stat; printf '\\n\\033[1mUnstaged changes:\\033[0m\\n'; git diff --stat";
      rem = "reminders";
      update = "sudo nixos-rebuild switch --flake .#${host}";
      screenshot = "maim -s | xclip -selection clipboard -t image/png";
      fv = "vim \$(fzf)";
      cb = "xclip -sel clipboard";
      ocaml = "utop";
    };
  };
}
