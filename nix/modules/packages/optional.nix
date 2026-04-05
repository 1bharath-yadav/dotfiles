{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-sdk-cmdline-tools-latest android-sdk-platform-tools
    aircrack-ng fcrackzip john
    f3 smartmontools
    gogcli goaccess httrack lynx monolith nyx payload-dumper-go
    netcat-openbsd sshfs tor traceroute
    acpi ent fq speedtest-cli
  ];
}