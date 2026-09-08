{ pkgs, ... }:

let
  bluetoothRofi = pkgs.writeShellApplication {
    name = "bluetooth-rofi";
    runtimeInputs = with pkgs; [
      bluez
      coreutils
      gawk
      rofi
    ];
    text = builtins.readFile ../home/script/bluetooth-rofi;
  };
in
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  environment.systemPackages = [ bluetoothRofi ];
}
