{ config, ... }:

{
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  networking.networkmanager.dns = "systemd-resolved";

  services.resolved.enable = true;

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."networks".path ];

    profiles = {
      illinoisnet = {
        connection = {
          id = "IllinoisNet";
          type = "wifi";
          autoconnect = "true";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "IllinoisNet";
        };
        wifi-security = {
          key-mgmt = "wpa-eap";
        };
        "802-1x" = {
          eap = "$net2_eap";
          phase2-auth = "$net2_phase2_auth";
          identity = "$net2_identity";
          password = "$net2_password";
        };
        ipv4 = {
          method = "auto";
          dns = "1.1.1.1;1.0.0.1;";
          ignore-auto-dns = "true";
        };
      };

      apartment = {
        connection = {
          id = "508CLRK-U411";
          uuid = "0b5e5127-f7c8-4c68-ab53-57cd2ad5d4d6";
          type = "wifi";
          autoconnect = "true";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "508CLRK-U411";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$apartment_password";
        };
        ipv4 = {
          method = "auto";
          dns = "1.1.1.1;1.0.0.1;";
          ignore-auto-dns = "true";
        };
        ipv6 = {
          method = "disabled";
        };
      };
    };
  };

  systemd.services."NetworkManager-ensure-profiles" = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };
}
