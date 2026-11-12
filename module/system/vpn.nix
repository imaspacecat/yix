{ lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.openconnect ];

  networking.networkmanager = {
    plugins = [ pkgs.networkmanager-openconnect ];

    ensureProfiles.profiles =
      lib.mapAttrs
        (name: group: {
          connection = {
            id = name;
            type = "vpn";
            autoconnect = false;
          };
          vpn = {
            service-type = "org.freedesktop.NetworkManager.openconnect";
            gateway = "vpn.illinois.edu";
            protocol = "anyconnect";
            useragent = "AnyConnect";
            prevent_invalid_cert = "yes";
            cookie-flags = 2;
          };
          vpn-secrets."form:main:group_list" = group;
          ipv4 = {
            method = "auto";
            dns-priority = -50;
            dns-search = "~.;";
          };
          ipv6 = {
            method = "auto";
            dns-priority = -50;
            dns-search = "~.;";
          };
        })
        {
          "Illinois VPN (Split)" = "OpenConnect1 (Split)";
          "Illinois VPN (All)" = "OpenConnect2 (All)";
        };
  };
}
