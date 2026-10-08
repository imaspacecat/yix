{ lib, pkgs, ... }:

let
  reminderDefaults = pkgs.writeText "reminders.json" ''
    {
      "reminders": [

      ]
    }
  '';

  reminderCli = pkgs.writeShellApplication {
    name = "reminders";
    runtimeInputs = with pkgs; [
      libnotify
      python3
    ];
    text = ''
      exec python3 ${./script/reminders-cli} "$@"
    '';
  };

  hourlyReminder = pkgs.writeShellApplication {
    name = "hourly-reminder";
    runtimeInputs = [ reminderCli ];
    text = ''
      if [[ $# -eq 0 || -z "$*" ]]; then
        printf 'Usage: hourly reminder text\n' >&2
        exit 1
      fi
      reminders add --every 1h -- "$*"
      reminders check
    '';
  };
in
{
  home.packages = [ reminderCli hourlyReminder ];

  home.activation.createRemindersFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    reminder_dir="$HOME/.config/reminders"
    reminder_file="$reminder_dir/reminders.json"

    if [ ! -e "$reminder_file" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$reminder_dir"
      ${pkgs.coreutils}/bin/cp ${reminderDefaults} "$reminder_file"
    fi
  '';

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
