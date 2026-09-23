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
          --zen-element-separation: 0px !important;
        }

        #navigator-toolbox,
        #TabsToolbar,
        #TabsToolbar-customization-target,
        #zen-sidebar-top-buttons,
        #zen-sidebar-foot-buttons,
        #zen-tabs-wrapper {
          background-color: #000000 !important;
        }
      '';

      settings = {
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
