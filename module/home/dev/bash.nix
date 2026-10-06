{ pkgs, host, ... }:

let
  screenshot-script = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      coreutils
      maim
      xclip
    ];
    text = ''
      capture_args=(-s)
      if [[ "''${1:-}" == "--full" ]]; then
        capture_args=()
        shift
      fi
      capture_file=$(mktemp --suffix=.png)
      trap 'rm -f "$capture_file"' EXIT
      maim "''${capture_args[@]}" "$@" "$capture_file"
      xclip -selection clipboard -t image/png -i "$capture_file"
    '';
  };

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
  home.packages = [
    cpd-script
    screenshot-script
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      gstat = "printf '\\033[1mStaged changes:\\033[0m\\n'; git diff --staged --stat; printf '\\n\\033[1mUnstaged changes:\\033[0m\\n'; git diff --stat";
      rem = "reminders";
      update = "sudo nixos-rebuild switch --flake .#${host}";
      fv = "vim \$(fzf)";
      cb = "xclip -sel clipboard";
      ocaml = "utop";
    };
  };
}
