# Design System: Bloom

**Skill:** stitch-design-taste · **Platform:** Flutter mobile app (iOS + Android), portrait phone first
**Source of truth in code:** `mobile/lib/app/theme/` (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`). If this file and the code disagree, fix one of them. Never let them drift.

---

## Configuration

| Dial | Level | Meaning for Bloom |
|---|---|---|
| **Creativity** | `4` | Quiet and warm, with personality in color and copy, not in layout tricks |
| **Density** | `4` | "Daily App Balanced": one clear job per screen, generous breathing room |
| **Variance** | `3` | "Predictable Symmetric": a habit app is used half-awake at 7am, so every screen is found where it was yesterday |
| **Motion Intent** | `3` | "Static Restrained": motion only to confirm an action or show a state change |

> When prompting Stitch, say: *"Follow the Bloom DESIGN.md. Mobile portrait, 390 x 844."*

---

## 1. Visual Theme & Atmosphere

A calm, natural-minimalist habit companion. The interface feels like a well-kept notebook on a sunlit kitchen table: warm cream paper, sage ink, and soft rounded shapes that invite a thumb. Nothing shouts. Progress is shown gently and celebrated briefly, then the app gets out of the way.

- **Mood words:** grounded, unhurried, tactile, kind
- **Density:** balanced. One primary action per screen, cards stacked with clear gaps
- **Variance:** low. Consistent single-column structure, left-aligned headings, the same header rhythm on every tab
- **Motion:** restrained. Short, soft transitions that confirm a tap. No ambient animation
- **Theme:** light only. There is no dark theme yet. Do not design one until it is requested

---

## 2. Color Palette & Roles

### Surfaces (warm neutral family, never mix in cool grays)
- **Warm Cream Canvas** (#FBF9F4): screen background for every page
- **Paper White** (#FFFFFF): highest-elevation cards such as routine cards and step cards in edit mode
- **Recessed Sand** (#F5F3EE): input fields, secondary panels, grouped content blocks
- **Habit Card Sand** (#F0EEE9): default card fill for habit rows and chips
- **Sheet Sand** (#EAE8E3): bottom sheets and modal surfaces
- **Deep Sand** (#E4E2DD): inactive progress segments, disabled fills

### Ink
- **Deep Charcoal Ink** (#1B1C19): primary text and icons. Never pure black
- **Moss Grey** (#434844): secondary labels, descriptions, helper text
- **Stone Outline** (#737873): tertiary text, metadata, inactive icons
- **Hairline Sage** (#C3C8C2): 1px dividers and drag handles

### Accent (the ONE interface accent)
- **Sage Green** (#4D6054): primary buttons, active tab, completed check-offs, focus rings, links. Saturation well under 80%
- **Pale Sage** (#D2E8D8): success tints behind check icons, "logged" toasts, completion badges

### Routine identity colors (user-chosen, scoped)
A routine may carry ONE of these as its identity color. It tints only that routine's own surfaces: its card accents, its player screen, its completion screen. It never recolors global UI such as tabs, headers or unrelated screens.
- **Sage Green** (#4D6054): default
- **Sky Slate** (#4C5F69): focus and work routines
- **Dusty Rose** (#7C5454): evening and reflection routines
- **Warm Olive** (#66796C): weekend and restoration routines

Text and icons on a routine color are white (#FFFFFF). Tinted backgrounds use the routine color at 12 to 15 percent opacity.

### Status
- **Alert Red** (#BA1A1A) on **Blush** (#FFDAD6): errors only (validation, failed sync). Never decorative

### Banned colors
- Purple or violet gradients, neon glows, "AI blue" highlights
- Pure black (#000000) and pure white page backgrounds (#FFFFFF is for cards, not canvases)
- Any cool gray (slate, zinc) mixed into the warm sand family
- A second interface accent. Dusty Rose and Sky Slate exist only as routine identity colors

---

## 3. Typography Rules

One family: **Manrope** (Google Fonts), used for everything. Hierarchy comes from weight and size, never from a second typeface.

| Role | Size / line height | Weight | Tracking | Use |
|---|---|---|---|---|
| Display | 40 / 48 | 700 | -0.02em | Rare: celebration numbers, onboarding |
| Headline Large | 32 / 40 (28 / 36 on phones) | 600 | -0.01em | Screen titles ("Your Routines") |
| Headline Medium | 24 / 32 | 600 | 0 | App bar titles, card titles, routine names |
| Headline Small | 20 / 28 | 600 | 0 | Section headings |
| Body Large | 18 / 28 | 400 | 0 | Input text, featured descriptions |
| Body Medium | 16 / 24 | 400 | 0 | Default paragraph text |
| Body Small | 14 / 20 | 400 | 0 | Secondary descriptions, Moss Grey |
| Label Large | 14 / 20 | 600 | +0.01em | Button labels |
| Label Medium | 14 / 20 | 500 | +0.01em | Chip text, list metadata |
| Label Small | 12 / 16 | 600 | +0.05em | Form field labels, tiny badges |

- **Body line length:** keep paragraphs short. Two to three lines on a phone is the target
- **Numbers:** timers and streak counts use Manrope with tabular figures so digits do not jitter while counting
- **Uppercase labels:** allowed ONLY as form field labels ("ROUTINE NAME") and at most ONE section label per screen. Never an uppercase label above every section
- **Banned:** Inter, any serif, any second display font, monospace outside timers, gradient text

---

## 4. Screen Header (replaces the web "Hero")

Every top-level tab opens with the same header so the app feels predictable:
1. **Top bar:** small Bloom leaf mark in a 36px sage-tinted rounded square, the word "Bloom" in Headline Medium, one optional trailing icon button. Left-aligned
2. **Title block:** screen title in Headline Large, one-line subtitle in Body Medium, Moss Grey
3. **Optional helper card:** one Recessed Sand card with an icon and at most two sentences

Detail and form screens use a standard app bar instead: back arrow on the left, a Headline Medium title, no centered titles.

- One primary action per screen, visible without scrolling or pinned at the bottom
- No marketing-style heroes, no oversized display type on everyday screens, no filler text such as "Swipe to explore"

---

## 5. Component Stylings

* **Primary buttons:** full-width pill (fully rounded), 56px tall, Sage Green (or the routine's identity color inside a routine) with white Label Large text. Flat, no shadow glow. On press: scale to 0.98 and darken slightly
* **Secondary buttons:** full-width pill, 56px tall, 1.5px outline in the accent color, transparent fill. Tertiary actions are plain text buttons in the accent color
* **Destructive actions:** text button in Dusty Rose (#7C5454) with a short plain explanation below it. Never a big red filled button
* **Cards:** 24px rounded corners, no border. Habit Card Sand fill for lists, Paper White with a whisper shadow for elevated items. Whisper shadow: sage-tinted, 4 percent opacity, 30px blur, 8px down (`rgba(77,96,84,0.04)`). Internal padding 20px (24px for large cards)
* **Chips and badges:** fully rounded pills, Deep Sand or accent tint at 12 percent, Label Small or Label Medium text
* **Inputs:** fully rounded pill fields (multi-line fields use 24px corners), Recessed Sand fill, no border at rest, 1.5px Sage Green border on focus, 1.5px Alert Red border on error. Uppercase Label Small label ABOVE the field, error text BELOW it. No floating labels, and never a placeholder used as the only label
* **Lists and steps:** each row is a card with a leading icon inside a tinted circle (32 to 36px), a title in Label Large, and metadata ("5 min · Movement") in Label Small. Reorderable rows show a drag handle in Hairline Sage on the left
* **Bottom navigation:** a floating dock with 32px rounded corners, frosted Warm Cream at 85 percent opacity with a 20px blur, and a whisper shadow. The active tab uses Sage Green, inactive tabs use Stone Outline
* **Bottom sheets:** Sheet Sand, 24px top corners, a drag handle, and a single primary action at the bottom
* **Progress:** step progress is a row of thin 4px rounded segments (done and current = accent color, upcoming = Deep Sand). Timers are one circular ring, 6px stroke, accent on Recessed Sand track
* **Loading:** skeleton blocks shaped like the final cards, in Deep Sand with a slow, subtle shimmer. Spinners only for sub-second button busy states
* **Empty states:** a tinted circle with one icon, one sentence saying what goes here, and one action to add the first item. Never a bare "No data"
* **Error states:** inline under the field for forms. A calm card with a retry action for failed loads. The offline screen is a full friendly stop, not a toast
* **Icons:** Material Symbols, rounded style, one weight across the app. Custom-drawn icons only for Bloom's own marks (the leaf, the routine loop)

---

## 6. Layout Principles

- **Canvas:** portrait phone, designed at 390 x 844. Must work from 360 to 430 wide
- **Margins:** 24px left and right on every screen
- **Rhythm:** 16px between cards, 40px between distinct sections, 8px between a label and its field
- **Structure:** single column. Two-column layouts only for small metric tiles (for example, two stat tiles side by side)
- **Touch:** every tap target at least 56px tall for one-handed use. Primary actions sit in the lower half of the screen, within thumb reach
- **Scroll space:** leave 100 to 110px at the bottom of scrolling screens so the floating dock never covers content
- **No overlap:** text never sits on top of images or other text. Floating elements are limited to the dock and a single pinned bottom action
- **Corner system (locked):** pills for buttons, inputs and chips. 24px for cards and sheets. 32px for the dock. 8 to 16px only for small icon containers

---

## 7. Motion & Interaction (build-phase intent)

> Stitch produces static screens. This section tells whoever builds the screen in Flutter how it should move.

- **Tone:** gentle and brief. Standard duration 200 to 300ms, easing `Curves.easeOutCubic`. Springs only for drag-and-drop settling
- **Check-off:** the habit row updates instantly (optimistic), and the check icon fills with a short scale-in. No confetti
- **Step change in the routine player:** the progress segment fills, then the next step's content cross-fades in
- **Completion screen:** one soft entrance of the medallion, then everything is still
- **Reorder:** dragged cards lift slightly (scale 1.02 plus whisper shadow) and neighbors slide into place
- **Allowed continuous motion:** ONLY the running timer ring and the breathing cue inside the routine player. Nothing else loops
- **Reduced motion:** when the system asks for reduced motion, replace every transition with an instant change and stop the breathing cue animation
- **Performance:** animate opacity and transform only. Keep blur limited to the navigation dock

---

## 8. Voice & Content

- Short, warm, plain sentences. "Small steps, done consistently." Not "Unlock your full potential"
- Speak to one person: "your routines", "you showed up today"
- Real habit names and realistic durations (2, 5, 10 minutes). No lorem ipsum, no "Habit 1"
- Numbers must come from the user's data. No invented statistics
- No emojis in the interface. Use icons
- Use a normal hyphen or a period, never an em dash, in interface copy

---

## 9. Anti-Patterns (Banned)

- Purple or neon gradients, glow shadows, glassmorphism anywhere except the navigation dock
- Pure black text or pure white page backgrounds
- A second interface accent, or cool grays mixed into the warm palette
- Inter, serif fonts, or any second typeface
- Centered page titles on top-level screens
- Uppercase labels above every section
- More than one primary button on a screen
- Square cards next to pill buttons (breaking the locked corner system)
- Placeholder-only inputs, floating labels, errors shown only in toasts
- Endless looping animations, bouncing icons, confetti
- Circular spinners for full-screen loading (use skeletons)
- Fake numbers ("98% of users"), generic names ("John Doe"), filler verbs ("Elevate", "Unleash", "Seamless")
- Emojis in the interface
- Text that overlaps images or other text
- Tap targets smaller than 56px, or primary actions placed out of thumb reach at the top of the screen
