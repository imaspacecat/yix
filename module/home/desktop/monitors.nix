{ pkgs, ... }:

let
  monitorLayout = pkgs.writeText "monitor-layout.py" (builtins.readFile ./monitor-layout.py);
in
{
  home.packages = [ pkgs.arandr ];

  systemd.user.services.monitor-layout = {
    Unit = {
      Description = "Arrange external displays above the laptop screen";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 ${monitorLayout} ${pkgs.xrandr}/bin/xrandr";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
