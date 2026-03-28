{ config, ... }:
{
  home.file.".local/bin" = {
    source = ./scripts;
    executable = true;
    recursive = true;
  };
}
