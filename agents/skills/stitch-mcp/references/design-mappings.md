# Design Mappings and Descriptors

Use these mappings to transform vague user requests into precise, high-fidelity design instructions.

## UI/UX Keyword Refinement

| Vague Term | Enhanced Professional Terminology |
|:---|:---|
| "menu at the top" | "sticky navigation bar with logo and list items" |
| "big photo" | "high-impact hero section with full-width imagery" |
| "list of things" | "responsive card grid with hover states and subtle elevations" |
| "button" | "primary call-to-action button with micro-interactions" |
| "form" | "clean form with labeled input fields, validation states, and submit button" |
| "picture area" | "hero section with focal-point image or video background" |
| "sidebar" | "collapsible side navigation with icon-label pairings" |
| "popup" | "modal dialog with overlay and smooth entry animation" |
| "search bar" | "search input with magnifying glass icon, pill-shaped, subtle gray background" |
| "tabs" | "segmented tab navigation with active indicator and smooth transitions" |
| "settings page" | "organized settings layout with grouped sections and toggle switches" |
| "dashboard" | "data-dense overview with stat cards, charts, and activity feeds" |
| "profile page" | "user profile with avatar, bio section, and activity timeline" |
| "pricing page" | "tiered pricing cards with feature comparison and highlighted recommended plan" |
| "onboarding" | "step-by-step onboarding wizard with progress indicator and illustrations" |

## Atmosphere and Vibe Descriptors

| Basic Vibe | Enhanced Design Description |
|:---|:---|
| "Modern" | "Clean, minimal, with generous whitespace and high-contrast typography." |
| "Professional" | "Sophisticated, trustworthy, utilizing subtle shadows and a restricted, premium palette." |
| "Fun / Playful" | "Vibrant, organic, with rounded corners, bold accent colors, and bouncy micro-animations." |
| "Dark Mode" | "Electric, high-contrast accents on deep slate or near-black backgrounds." |
| "Luxury" | "Elegant, spacious, with fine lines, serif headers, and a focus on high-fidelity photography." |
| "Tech / Cyber" | "Futuristic, neon accents, glassmorphism effects, and technological monospaced typography." |
| "Warm / Organic" | "Earthy tones, natural textures, rounded shapes, warm and inviting palette." |
| "Editorial" | "Magazine-style layout, generous typography, asymmetric grids, strong visual hierarchy." |
| "Brutalist" | "Raw, unpolished, high contrast, exposed structure, bold type-driven layout." |
| "Glassmorphism" | "Semi-transparent surfaces, frosted glass effect, layered depth with backdrop blur." |
| "Neomorphism" | "Soft shadows, extruded surfaces, subtle 3D effect on flat backgrounds." |

## Geometry and Shape Translation

| Technical (CSS/Tailwind) | Natural Language for Stitch |
|---|---|
| `rounded-none` / `rounded-sm` | "Sharp, squared-off edges" or "slightly softened corners" |
| `rounded-md` / `rounded-lg` | "Gently rounded corners" or "generously rounded corners" |
| `rounded-xl` / `rounded-2xl` | "Very rounded, pillow-like containers" |
| `rounded-full` | "Pill-shaped buttons and tags" |
| `ROUND_FOUR` | Subtle rounding, professional feel |
| `ROUND_EIGHT` | Moderate rounding, modern feel (most common) |
| `ROUND_TWELVE` | Generous rounding, friendly feel |
| `ROUND_FULL` | Maximum rounding, pill/circular shapes |

## Depth and Elevation

| Style | Description |
|---|---|
| Flat | No shadows, focus on color blocking and borders. |
| Whisper-soft | Diffused, light shadows for subtle lift. |
| Floating | High-offset, soft shadows for elements that appear above the surface. |
| Inset | Inner shadows for pressable or nested elements. |
| Glassmorphism | Semi-transparent with backdrop blur and thin borders. |
| Neomorphic | Soft, extruded shadows creating a 3D relief effect. |

## Color Variant Guide

Map user aesthetic preferences to Stitch `colorVariant` values:

| User Says | colorVariant | Effect |
|---|---|---|
| "Keep it simple" / "one color" | `MONOCHROME` | Single-hue palette |
| "Professional" / "corporate" | `NEUTRAL` | Understated, low saturation |
| "Default" / "Material Design" | `TONAL_SPOT` | Standard Material You |
| "Bold" / "energetic" | `VIBRANT` | High saturation, bold |
| "Creative" / "artistic" | `EXPRESSIVE` | Wide color range |
| "Match my brand exactly" | `FIDELITY` | Closest to seed color |
| "Colorful" / "rainbow" | `RAINBOW` | Multi-hue spectrum |
| "Fun" / "playful" | `FRUIT_SALAD` | Varied, cheerful palette |

## Font Pairing Suggestions

| Style | Headline | Body | Label |
|---|---|---|---|
| Modern Tech | `GEIST` | `INTER` | `SPACE_GROTESK` |
| Professional | `MONTSERRAT` | `SOURCE_SANS_THREE` | `IBM_PLEX_SANS` |
| Editorial | `EB_GARAMOND` | `LITERATA` | `INTER` |
| Friendly SaaS | `PLUS_JAKARTA_SANS` | `DM_SANS` | `RUBIK` |
| Minimal | `INTER` | `INTER` | `INTER` |
| Bold Statement | `SORA` | `MANROPE` | `SPACE_GROTESK` |
| Elegant | `LIBRE_CASLON_TEXT` | `NEWSREADER` | `PUBLIC_SANS` |
| Startup / Trendy | `EPILOGUE` | `BE_VIETNAM_PRO` | `LEXEND` |
