"""Account-selection primitives for Claude Account Switcher."""
from __future__ import annotations
from dataclasses import dataclass

@dataclass(frozen=True)
class ClaudeProfile:
    id: str
    name: str
    email: str | None = None
    active: bool = False
    usage_pct: float | None = None
    remaining_pct: float | None = None


def choose_profile(profiles: list[ClaudeProfile], requested: str | None = None,
                   min_remaining: float = 70.0) -> ClaudeProfile:
    """Pick requested profile or the healthiest 5h profile."""
    if not profiles:
        raise RuntimeError("Claude Account Switcher returned no profiles")
    eligible = [p for p in profiles if p.remaining_pct is not None and p.remaining_pct >= min_remaining]
    if requested:
        key = requested.strip().lower()
        matches = [p for p in profiles if p.name.lower() == key or p.id.lower() == key]
        if not matches:
            raise RuntimeError(f"Claude profile not found: {requested}")
        p = matches[0]
        if p.remaining_pct is not None and p.remaining_pct < min_remaining:
            raise RuntimeError(f"Claude profile {p.name} has only {p.remaining_pct:.1f}% 5h remaining")
        return p
    if not eligible:
        raise RuntimeError(f"No Claude account has >= {min_remaining:.0f}% of the 5h window remaining")
    return max(eligible, key=lambda p: (p.remaining_pct or 0.0, p.active))
