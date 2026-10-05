{ inputs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;

    profiles.spacecat = {
      id = 0;
      name = "spacecat";
      isDefault = true;

      userChrome = ''
        :root {
          color-scheme: dark !important;
          --zen-primary-color: #8ab4f8 !important;
          --zen-branding-bg: #000000 !important;
          --zen-colors-primary: #111111 !important;
          --zen-colors-secondary: #1c1c1c !important;
          --zen-colors-tertiary: #000000 !important;
          --zen-colors-hover-bg: #222222 !important;
          --zen-colors-primary-foreground: #f2f2f2 !important;
          --zen-colors-border: #282828 !important;
          --zen-colors-border-contrast: #404040 !important;
          --zen-colors-input-bg: #111111 !important;
          --zen-main-browser-background: #000000 !important;
          --zen-main-browser-background-toolbar: #000000 !important;
          --zen-sidebar-themed-icon-fill: #e0e0e0 !important;
          --toolbox-bgcolor: #000000 !important;
          --toolbox-textcolor: #f2f2f2 !important;
          --toolbar-bgcolor: #000000 !important;
          --toolbar-color: #f2f2f2 !important;
          --toolbar-field-background-color: #111111 !important;
          --toolbar-field-color: #f2f2f2 !important;
          --toolbar-field-focus-background-color: #111111 !important;
          --toolbar-field-focus-color: #f2f2f2 !important;
          --toolbarbutton-icon-fill: #e0e0e0 !important;
          --toolbarbutton-hover-background: #222222 !important;
          --toolbarbutton-active-background: #303030 !important;
          --arrowpanel-background: #111111 !important;
          --arrowpanel-color: #f2f2f2 !important;
          --arrowpanel-border-color: #282828 !important;
          --panel-background: #111111 !important;
          --panel-color: #f2f2f2 !important;
        }

        #main-window,
        #navigator-toolbox,
        #TabsToolbar,
        #zen-sidebar-top-buttons,
        #zen-sidebar-foot-buttons,
        #zen-tabs-wrapper {
          background: #000000 !important;
          color: #f2f2f2 !important;
        }

        #zen-workspaces {
          --tab-background-color-selected: #262626 !important;
          --tab-selected-textcolor: #ffffff !important;
        }

        .tabbrowser-tab {
          color: #d0d0d0 !important;
        }

        .tabbrowser-tab:is([selected], [visuallyselected]) .tab-background {
          background: #262626 !important;
        }

        .tabbrowser-tab:is([selected], [visuallyselected]) .tab-label {
          color: #ffffff !important;
        }

        #urlbar-background {
          background: #111111 !important;
          border-color: #282828 !important;
        }
      '';

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.toolbar-theme" = 0;
        "browser.theme.content-theme" = 0;
        "layout.css.prefers-color-scheme.content-override" = 0;

        "browser.tabs.unloadOnLowMemory" = true;
        "browser.tabs.fadeOutUnloadedTabs" = true;
        "zen.tab-unloader.timeout" = 5;
        "zen.tab-unloader.excluded-urls" = "";

        "browser.sessionstore.restore_on_demand" = true;
        "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
        "browser.newtab.preload" = false;
        "browser.tabs.insertAfterCurrent" = true;
        "network.prefetch-next" = false;
        "network.dns.disablePrefetch" = true;
        "network.predictor.enabled" = false;

        "dom.ipc.processCount" = 4;
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications."application/pdf" = [ "zen-beta.desktop" ];
  };
}
