# Design System: Pulse Fitness

**Project ID:** 6139132077804554844

## 1. Visual Theme & Atmosphere

High-energy, performance-driven dark interface. The overall vibe is powerful and motivating -- think sports car dashboard meets premium fitness tracker. Dense information display with breathing room around key metrics. Purposeful use of color to guide the eye toward actionable elements.

## 2. Color Palette & Roles

- **Racing Red** (#e11d48) -- Primary accent for CTA buttons, active states, and progress indicators. Commands immediate attention.
- **Deep Obsidian** (#0f172a) -- Primary background, creating depth and making accent colors pop.
- **Slate Surface** (#1e293b) -- Card backgrounds and elevated surfaces, providing subtle layering against the obsidian base.
- **Silver Text** (#94a3b8) -- Secondary text, labels, and metadata. Readable without competing with primary content.
- **Pure White** (#ffffff) -- Headlines, primary stat values, and critical information.
- **Success Emerald** (#22c55e) -- Positive feedback, goal completion, and upward trends.

## 3. Typography Rules

- **Headlines:** Montserrat Bold -- condensed, impactful, conveys speed and strength
- **Body:** Inter Regular -- clean, highly legible at all sizes
- **Labels:** Space Grotesk Medium -- technical, monospaced feel for stat labels and metadata
- **Size scale:** 14px labels, 16px body, 24px section heads, 48px hero stats

## 4. Component Stylings

- **Buttons:** ROUND_EIGHT corners, Racing Red fill for primary, ghost outline for secondary. Subtle shadow on hover.
- **Cards:** ROUND_TWELVE corners, Slate Surface (#1e293b) background, 1px border at 10% white opacity. No heavy shadows -- depth comes from background contrast.
- **Inputs:** Rounded inputs with Slate Surface fill, subtle border on focus transitioning to Racing Red.
- **Stat cards:** Large numeric display (Montserrat Bold 32px), small label beneath (Space Grotesk 12px), optional sparkline.

## 5. Layout Principles

- **Grid:** 12-column base, 4-column for mobile
- **Spacing:** 16px base unit, 24px between card groups, 48px between sections
- **Hierarchy:** Stats and metrics get the most visual weight; navigation is minimal and unobtrusive
- **Responsive:** Desktop shows full dashboard grid; mobile stacks into scrollable card list
