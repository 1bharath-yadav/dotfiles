{ config, ... }:
{
  home.file."bin" = {
    source = ./scripts;
    executable = true;
    recursive = true;
  };
}
