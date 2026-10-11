{ pkgs, ... }:

let
  reminderCli = pkgs.writeShellApplication {
    name = "reminders";
    runtimeInputs = with pkgs; [
      libnotify
      python3
    ];
    text = ''
      exec python3 ${../../scripts/reminders-cli} "$@"
    '';
  };

  hourlyReminder = pkgs.writeShellApplication {
    name = "hourly-reminder";
    runtimeInputs = [ reminderCli ];
    text = builtins.readFile ../../scripts/hourly-reminder;
  };
in
{
  home.packages = [ reminderCli hourlyReminder ];

  systemd.user.services.reminders = {
    Unit = {
      Description = "Send due reminders";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${reminderCli}/bin/reminders check";
    };
  };

  systemd.user.timers.reminders = {
    Unit.Description = "Check reminders every minute";
    Timer = {
      OnCalendar = "*-*-* *:*:00";
      Persistent = true;
      Unit = "reminders.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
