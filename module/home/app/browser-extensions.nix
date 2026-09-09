{ ... }:

let
  autoTabDiscardId = "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}";

  extensionSettings = {
    "{bc16b6e3-4935-42b3-bff7-b65b49434857}" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/amoled-black/latest.xpi";
    };
    "uBlock0@raymondhill.net" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      private_browsing = true;
    };
    "{08ed11c3-efeb-4275-8887-5b1fc9dfc183}" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/terrakok-fuzzytabs/latest.xpi";
    };
    "${autoTabDiscardId}" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi";
    };
    "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
    };
  };

  autoTabDiscardSettings = {
    period = 60;
    number = 0;
    mode = "url-based";
    "whitelist-url" = [ "re:^https?://([a-zA-Z0-9-]+\\.)*linkedin\\.com(?:[/:?]|$)" ];
  };

  browserPolicies = {
    ExtensionSettings = extensionSettings;
    "3rdparty".Extensions."${autoTabDiscardId}" = autoTabDiscardSettings;
    Permissions = {
      Camera.Allow = [
        "https://meet.google.com"
        "https://zoom.us"
        "https://*.zoom.us"
      ];
      Microphone.Allow = [
        "https://meet.google.com"
        "https://zoom.us"
        "https://*.zoom.us"
      ];
      ScreenShare.Allow = [
        "https://meet.google.com"
        "https://zoom.us"
        "https://*.zoom.us"
      ];
    };
  };
in
{
  programs.firefox.policies = browserPolicies;
  programs.zen-browser.policies = browserPolicies;
}
