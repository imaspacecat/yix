{ pkgs, ... }:

{
  home.packages = [ pkgs.arandr ];

  systemd.user.services.monitor-layout = {
    Unit = {
      Description = "Arrange external displays above the laptop screen";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 ${../../../scripts/monitor-layout} ${pkgs.xrandr}/bin/xrandr";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
