# Android packages — nix-on-droid host
# The yazi module (programs.yazi) handles package installation.
{ ... }:

{
  imports = [ ../programs/yazi ];
}
