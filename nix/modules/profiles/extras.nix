# profiles/extras.nix — optional/niche tools; import manually when needed
#
# NOT imported by default. Add to a host file to enable:
#   imports = [ ../profiles/extras.nix ];
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Security / pentesting ────────────────────────────────────────────────────
    aircrack-ng   # wifi auditing
    fcrackzip     # zip password cracker
    john          # password cracker

    # ── Forensics / disk ────────────────────────────────────────────────────────
    f3            # flash memory test
    smartmontools # disk SMART data

    # ── Rare utilities ──────────────────────────────────────────────────────────
    antigravity   # python easter egg (lol)
    gogcli        # GOG CLI
    goaccess      # nginx log analyzer
    httrack       # website copier
    lynx          # terminal browser
    monolith      # save webpage as single file
    nyx           # tor controller
    payload-dumper-go  # Android payload.bin extractor

    # ── Network deep-dive ───────────────────────────────────────────────────────
    msmtp         # SMTP mail sender
    netcat-openbsd
    sshfs
    tor
    traceroute

    # ── Encoding / security ──────────────────────────────────────────────────────
    acpi
    ent           # entropy analysis
    fq            # binary format explorer
    speedtest-cli
  ];
}
