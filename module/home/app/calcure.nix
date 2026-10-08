{ pkgs, ... }:

{
  home.packages = [ pkgs.calcure ];

  xresources.properties = {
    "calcure.background" = "#101014";
    "calcure.foreground" = "#e6d5dd";
    "calcure.cursorColor" = "#f2a7c3";
    "calcure.cursorColor2" = "#101014";
    "calcure.highlightColor" = "#49303f";
    "calcure.highlightTextColor" = "#ffe4ef";
    "calcure.color0" = "#101014";
    "calcure.color1" = "#df7895";
    "calcure.color2" = "#b6a0b5";
    "calcure.color3" = "#e5b4b8";
    "calcure.color4" = "#d58eae";
    "calcure.color5" = "#b38eaf";
    "calcure.color6" = "#f2a7c3";
    "calcure.color7" = "#e6d5dd";
    "calcure.color8" = "#49303f";
    "calcure.color9" = "#f08eab";
    "calcure.color10" = "#cbb5ca";
    "calcure.color11" = "#f4c8cc";
    "calcure.color12" = "#e9a4c4";
    "calcure.color13" = "#cba4c7";
    "calcure.color14" = "#ffc1d9";
    "calcure.color15" = "#ffe4ef";
  };

  xdg.configFile."calcure/config.ini" = {
    force = true;
    text = ''
      [Parameters]
      default_view = calendar
      default_calendar_view = monthly
      split_screen = Yes
      right_pane_percentage = 30
      journal_header = TASKS
      show_calendar_borders = Yes
      minimal_today_indicator = No
      minimal_days_indicator = No
      minimal_weekend_indicator = No
      show_current_time = Yes
      show_moon_phases = Yes
      show_keybindings = Yes
      use_unicode_icons = Yes
      holiday_country = UnitedStates
      start_week_day = 1
      weekend_days = 6,7

      [Colors]
      color_today = 6
      color_events = 4
      color_days = 7
      color_day_names = 6
      color_weekends = 5
      color_weekend_names = 5
      color_hints = 5
      color_title = 4
      color_calendar_header = 4
      color_calendar_border = 5
      color_active_pane = 6
      color_separator = 5
      color_todo = 7
      color_done = 2
      color_important = 3
      color_deadlines = 1
      color_holidays = 3
      color_birthdays = 5
      color_time = 5
      color_background = -1

      [Styles]
      bold_today = Yes
      bold_day_names = Yes
      bold_weekend_names = Yes
      bold_title = Yes
      bold_active_pane = Yes
      underlined_today = Yes
    '';
  };
}
