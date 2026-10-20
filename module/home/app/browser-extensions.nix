let
  autoTabDiscardId = "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}";
  meetingSites = [
    "https://meet.google.com"
    "https://zoom.us"
    "https://*.zoom.us"
    "https://gov.teams.microsoft.us"
    "https://www.meritfirst.us"
    "https://meritfirst.us"
    "https://www.loom.com"
    "https://codesignal.com"
    "https://*.codesignal.com"
  ];
in
{
  programs.zen-browser.policies = {
    PopupBlocking.Allow = [
      "https://zoom.us"
      "https://zoom.com"
      "https://zoomgov.com"
    ];
    ExtensionSettings = {
      "{bc16b6e3-4935-42b3-bff7-b65b49434857}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/amoled-black/latest.xpi";
      };
      "uBlock0@raymondhill.net" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        private_browsing = true;
      };
      "myallychou@gmail.com" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
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
    "3rdparty".Extensions."${autoTabDiscardId}" = {
      period = 60;
      number = 0;
      mode = "url-based";
      "whitelist-url" = [ "re:^https?://([a-zA-Z0-9-]+\\.)*linkedin\\.com(?:[/:?]|$)" ];
    };
    "3rdparty".Extensions."uBlock0@raymondhill.net" = {
      toOverwrite.filters = [
        "||amazon.*^$removeparam=/^(?:__mk_[a-z]{1,3}_[a-z]{1,3}|_encoding|aaxitk|ascsubtag|camp|content-id|creative|creativeASIN|crid|cv_ct_[a-z]+|dib|dib_tag|dchild|field-lbr_brands_browse-bin|hsa_cr_id|keywords|linkCode|ms3_c|p[fd]_rd_[a-z]+|qid|qualifier|ref_?|refRID|s|sb-ci-[a-z]+|smid|spIA|sprefix|sr|srs|starsLeft|th)=/"
      ];
    };
    Permissions = {
      Camera.Allow = meetingSites;
      Microphone.Allow = meetingSites;
      ScreenShare.Allow = [
        "https://codesignal.com"
        "https://*.codesignal.com"
        "https://meet.google.com"
        "https://zoom.us"
        "https://*.zoom.us"
        "https://www.meritfirst.us"
        "https://meritfirst.us"
      ];
    };
  };
}
