{ pkgs, lib, ... }:

let
  ewwPackages = import ./eww/packages.nix { inherit pkgs lib; };
  inherit (ewwPackages)
    workspaceIconBar
    codexbar
    backlightBar
    volumeBar
    wlanBar
    wifiNetworks
    wifiAction
    panelClose
    panelToggle
    ramProcesses
    batteryBar
    brightnessAction
    volumeAction
    ;

  ewwCommands = {
    workspaceIconBar = "${workspaceIconBar}/bin/workspace-icon-bar";
    backlightBar = "${backlightBar}/bin/backlight-bar";
    volumeBar = "${volumeBar}/bin/volume-bar";
    wlanBar = "${wlanBar}/bin/wlan-bar";
    batteryBar = "${batteryBar}/bin/battery-bar";
    codexbar = "${codexbar}/bin/codexbar";
    brightnessAction = "${brightnessAction}/bin/brightness-action";
    volumeAction = "${volumeAction}/bin/volume-action";
    networkEditor = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
    wifiNetworks = "${wifiNetworks}/bin/wifi-networks";
    wifiAction = "${wifiAction}/bin/wifi-action";
    panelClose = "${panelClose}/bin/panel-close";
    ramProcesses = "${ramProcesses}/bin/ram-processes";
    ramToggle = "${panelToggle}/bin/panel-toggle ram-panel 360";
    wifiToggle = "${panelToggle}/bin/panel-toggle wifi-panel 340";
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
  home.packages = [
    pkgs.eww
    pkgs.networkmanagerapplet
    workspaceIconBar
    codexbar
    backlightBar
    volumeBar
    wlanBar
    batteryBar
    brightnessAction
    volumeAction
    wifiNetworks
    wifiAction
    panelClose
    panelToggle
    ramProcesses
  ];

  xdg.configFile."eww/eww.yuck".text = replaceEww ./eww/eww.yuck;
  xdg.configFile."eww/workspaces.yuck".text = replaceEww ./eww/workspaces.yuck;
  xdg.configFile."eww/status.yuck".text = replaceEww ./eww/status.yuck;
  xdg.configFile."eww/wifi.yuck".text = replaceEww ./eww/wifi.yuck;
  xdg.configFile."eww/eww.scss".source = ./eww/eww.scss;

  systemd.user.services.eww = {
    Unit = {
      Description = "Eww bar";
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
            workspaceIconBar
            codexbar
            backlightBar
            volumeBar
            wlanBar
            batteryBar
            brightnessAction
            volumeAction
            wifiNetworks
            wifiAction
            panelClose
            panelToggle
            ramProcesses
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
