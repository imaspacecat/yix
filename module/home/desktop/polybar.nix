{ pkgs, lib, ... }:

let
  codexbar = pkgs.writeShellApplication {
    name = "codexbar";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnused
      jq
    ];
    text = builtins.readFile ../../../scripts/codexbar.sh;
  };
in

{
  services.network-manager-applet.enable = true;

  home.packages = [ codexbar ];

  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
    };

    script = "exec polybar top";

    config = {
      "settings" = {
        "screenchange-reload" = true;
        format-background = "#E6222222";
        format-padding = 1;
      };

      "bar/top" = {
        width = "100%";
        height = "24px";
        background = "#00000000";
        foreground = "#ffffff";
        font-0 = "JetBrainsMono Nerd Font:pixelsize=11;2";
        line-size = 2;
        modules-left = "i3";
        modules-right = "cpu memory backlight pulseaudio battery codexbar date tray";
      };

      "module/tray" = {
        type = "internal/tray";
        tray-background = "#E6222222";
        tray-size = "16px";
        tray-spacing = "6px";
      };

      "module/i3" = {
        type = "internal/i3";
        format = "<label-state>";
        index-sort = true;
        format-padding = 0;
        label-focused = "%index%";
        label-focused-background = "#444444";
        label-focused-underline = "#ffffff";
        label-focused-padding = "12px";
        label-unfocused = "%index%";
        label-unfocused-padding = "12px";
        label-visible = "%index%";
        label-visible-padding = "12px";
        label-urgent = "%index%";
        label-urgent-background = "#b7791f";
        label-urgent-underline = "#f6c85f";
        label-urgent-padding = "12px";
      };

      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format = "󰍛 <label>";
        label = "%percentage%%";
      };

      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        label = "%percentage_used%%";
        format = "%{A1:${pkgs.rxvt-unicode}/bin/urxvt -e ${pkgs.btop}/bin/btop:}󰘚 <label>%{A}";
      };

      "module/backlight" = {
        type = "internal/backlight";
        card = "intel_backlight";
        format = "%{A4:${pkgs.brightnessctl}/bin/brightnessctl set 5%+:}%{A5:${pkgs.brightnessctl}/bin/brightnessctl set 5%-:}󰃠 <label>%{A}%{A}";
        label = "%percentage%%";
        enable-scroll = false;
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "󰕾 <label-volume>";
        label-volume = "%percentage%%";
        label-muted = "󰖁 muted";
      };

      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "AC";
        poll-interval = 5;
        format-charging = "󰂅 <label-charging>";
        format-discharging = "󰁹 <label-discharging>";
        format-full = "󰁹 <label-full>";
        label-charging = "%percentage%%";
        label-discharging = "%percentage%%";
        label-full = "100%";
      };

      "module/codexbar" = {
        type = "custom/script";
        exec = "${codexbar}/bin/codexbar";
        interval = 10;
        format = "<label>";
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%Y-%m-%d";
        time = "%H:%M:%S";
        label = "%date% %time%";
        format = "%{A1:${pkgs.rxvt-unicode}/bin/urxvt -name calcure -title Calcure -geometry 120x36 -b 16 -e ${pkgs.calcure}/bin/calcure:}<label>%{A}";
      };
    };
  };

  systemd.user.services.polybar = {
    Service.Type = lib.mkForce "simple";
    Unit.PartOf = lib.mkForce [ "i3-session.target" ];
    Install.WantedBy = lib.mkForce [ "i3-session.target" ];
  };
}
