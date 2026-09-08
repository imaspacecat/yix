{ ... }:

{
  imports = [
    ./system/audio.nix
    ./system/bluetooth.nix
    ./system/libinput.nix
    ./system/network.nix
    ./system/sops.nix
    ./system/user.nix
    ./system/udev.nix
  ];

  home-manager.users.spacecat = {
    imports = [
      ../home.nix

      ./home/app/alacritty.nix
      ./home/app/browser-extensions.nix
      ./home/app/firefox.nix
      ./home/app/helium.nix
      ./home/app/obsidian.nix
      ./home/app/urxvt.nix
      ./home/app/zen.nix
      ./home/app/quartus.nix

      ./home/desktop/dunst.nix
      ./home/desktop/i3.nix
      ./home/desktop/monitors.nix
      ./home/desktop/picom.nix
      ./home/desktop/polybar.nix
      ./home/desktop/rofi.nix

      ./home/reminders.nix

      ./home/dev/bash.nix
      ./home/dev/fzf.nix
      ./home/dev/git.nix
      ./home/dev/ocaml.nix
      ./home/dev/python.nix
      ./home/dev/ssh.nix
      ./home/dev/vscode.nix
      ./home/dev/codex.nix
      ./home/dev/yazi.nix
    ];
  };
}
