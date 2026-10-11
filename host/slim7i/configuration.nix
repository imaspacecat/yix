{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
}
