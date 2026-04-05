{ pkgs, ... }:

# mise — runtime/version manager
#
# Version pin policy:
#   - Pin stable versions that you actively use across projects.
#   - Bump intentionally when you need newer features; not automatically.
#   - Keep in sync with what sync-external-tools installs via `mise install`.
#
# Why here instead of external.txt:
#   - This file is Home-Manager-managed and symlinked to Nix store.
#   - mise reads [tools] from config; we don't want it trying to write here.
#   - sync-external-tools just runs `mise install` to materialize the runtimes.

{
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".text = ''
    [tools]
    python = "3.12.13"
    node = "25.9.0"
    rust = "1.94.0"
    bun = "1.3.11"

    [settings]
    legacy_version_file = true
    idiomatic_version_file_enable_tools = ["python", "node", "rust", "bun"]
  '';
}