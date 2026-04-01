{ config, ... }:
{
  # Scripts are copied to ~/.local/bin on `nh home switch`.
  # mkOutOfStoreSymlink is used per-file for scripts that need live-editing;
  # bulk copy remains the default for the rest.
  home.file.".local/bin" = {
    source     = ./scripts;
    executable = true;
    recursive  = true;
  };
}
