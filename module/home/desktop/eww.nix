{ pkgs, lib, ... }:

let
  ewwPackages = import ./eww/packages.nix { inherit pkgs; };
  ewwCommands = lib.mapAttrs (_: lib.getExe) ewwPackages // {
    processMonitor = "${pkgs.rxvt-unicode}/bin/urxvt -e ${pkgs.btop}/bin/btop >/dev/null 2>&1 &";
  };

  replaceEww =
    file:
    let
      names = builtins.attrNames ewwCommands;
    in
    builtins.replaceStrings (map (name: "@${name}@") names) (map (name: ewwCommands.${name}) names) (
      builtins.readFile file
    );
in
{
  services.network-manager-applet.enable = true;
  xsession.preferStatusNotifierItems = true;

  home.packages = [
    pkgs.eww
    pkgs.networkmanagerapplet
  ];

  xdg.configFile."eww/eww.yuck".text = replaceEww ./eww/eww.yuck;
  xdg.configFile."eww/workspaces.yuck".text = replaceEww ./eww/workspaces.yuck;
  xdg.configFile."eww/status.yuck".text = replaceEww ./eww/status.yuck;
  xdg.configFile."eww/eww.scss".source = ./eww/eww.scss;

  systemd.user.services.eww = {
    Unit = {
      Description = "Eww bar";
      After = [
        "pipewire-pulse.socket"
        "wireplumber.service"
      ];
      Wants = [
        "pipewire-pulse.socket"
        "wireplumber.service"
      ];
      PartOf = [ "i3-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStartPre = "-${pkgs.procps}/bin/pkill -x eww";
      ExecStart = "${pkgs.eww}/bin/eww daemon";
      ExecStartPost = "${pkgs.eww}/bin/eww open bar";
      ExecStop = "${pkgs.eww}/bin/eww kill";
      RemainAfterExit = true;
      Environment = [
        "PATH=${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.i3
          ]
        }"
      ];
    };
    Install.WantedBy = [ "i3-session.target" ];
  };
}
