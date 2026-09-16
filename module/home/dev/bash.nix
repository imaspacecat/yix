{ pkgs, ... }:

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
      rem = "reminders";
      update = "sudo nixos-rebuild switch --flake .#loaner";
      screenshot = "maim -s | xclip -selection clipboard -t image/png";
      fv = "vim \$(fzf)";
      cb = "xclip -sel clipboard";
      ocaml = "utop";
    };
  };
}
