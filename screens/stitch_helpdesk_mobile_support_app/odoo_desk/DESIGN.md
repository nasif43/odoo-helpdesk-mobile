---
name: Odoo Desk
colors:
  surface: '#f6faff'
  surface-dim: '#d2dbe4'
  surface-bright: '#f6faff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#ecf5fe'
  surface-container: '#e6eff8'
  surface-container-high: '#e0e9f2'
  surface-container-highest: '#dbe4ed'
  on-surface: '#141d23'
  on-surface-variant: '#3e4949'
  inverse-surface: '#293138'
  inverse-on-surface: '#e9f2fb'
  outline: '#6e797a'
  outline-variant: '#bdc9c9'
  surface-tint: '#00696e'
  primary: '#006368'
  on-primary: '#ffffff'
  primary-container: '#017e84'
  on-primary-container: '#dffdff'
  inverse-primary: '#78d5db'
  secondary: '#79526f'
  on-secondary: '#ffffff'
  secondary-container: '#fac9ea'
  on-secondary-container: '#78516d'
  tertiary: '#00617d'
  on-tertiary: '#ffffff'
  tertiary-container: '#007b9f'
  on-tertiary-container: '#f0f9ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#95f1f8'
  primary-fixed-dim: '#78d5db'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f53'
  secondary-fixed: '#ffd7f1'
  secondary-fixed-dim: '#e9b8d9'
  on-secondary-fixed: '#2f1029'
  on-secondary-fixed-variant: '#5f3b56'
  tertiary-fixed: '#bee9ff'
  tertiary-fixed-dim: '#77d2fa'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#004d65'
  background: '#f6faff'
  on-background: '#141d23'
  surface-variant: '#dbe4ed'
typography:
  headline-xl:
    fontFamily: Roboto
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: 2.25rem
    letterSpacing: '0'
  headline-xl-mobile:
    fontFamily: Roboto
    fontSize: 1.5rem
    fontWeight: '700'
    lineHeight: 2rem
    letterSpacing: '0'
  headline-lg:
    fontFamily: Roboto
    fontSize: 1.3125rem
    fontWeight: '700'
    lineHeight: 1.75rem
    letterSpacing: '0'
  headline-md:
    fontFamily: Roboto
    fontSize: 1.125rem
    fontWeight: '700'
    lineHeight: 1.5rem
    letterSpacing: '0'
  body-lg:
    fontFamily: Roboto
    fontSize: 1rem
    fontWeight: '400'
    lineHeight: 1.5rem
    letterSpacing: '0'
  body-md:
    fontFamily: Roboto
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.3125rem
    letterSpacing: '0'
  body-sm:
    fontFamily: Roboto
    fontSize: 0.8125rem
    fontWeight: '400'
    lineHeight: 1.25rem
    letterSpacing: '0'
  label-lg:
    fontFamily: Roboto
    fontSize: 0.875rem
    fontWeight: '700'
    lineHeight: 1.25rem
    letterSpacing: '0'
  label-md:
    fontFamily: Roboto
    fontSize: 0.75rem
    fontWeight: '500'
    lineHeight: 1rem
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Roboto
    fontSize: 0.75rem
    fontWeight: '700'
    lineHeight: 1rem
    letterSpacing: 0.02em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.25rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-tablet: 1.5rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system is engineered to make the mobile helpdesk feel native to Odoo, serving customers and the business owner with the same visual language as the Helpdesk backend. It favors flat surfaces, hairline borders, and plain functional labeling over decorative effects, taking cues from Odoo's web client while adapting its form, kanban, and chatter patterns for touch.

### Brand Personality & Tone
- **Familiar & Practical:** Purpose-built for raising, triaging, and resolving tickets. Screens stay dense but calm, with plain labels and minimal ornament.
- **Flat & Bordered:** White cards and form sheets on a pale gray canvas, separated by 1px light-gray borders rather than shadows.
- **Two-Colour Identity:** Aubergine anchors the brand chrome, while a teal action colour drives every primary interaction, matching the Odoo Enterprise convention.

### Design Movement
- **Odoo Web Client, Adapted for Touch:** The flat, bordered, form-first language of Odoo's web client, expressed through mobile components (bottom navigation, floating action button, kanban-style ticket cards, bottom sheets) with 4px corners, pill badges, and underlined form fields.

## Colors

The palette centers on teal (`#017E84`) for primary actions, anchored by aubergine (`#714B67`) for brand chrome and by neutral grays for text and structure. Backgrounds maintain clarity with `#FFFFFF` for cards and form sheets and `#F8F9FA` for canvas backdrops.

### Specialized Semantic Status Tokens
Ticket lifecycles rely on unambiguous semantic tokens with dedicated foreground, muted container, and hairline border pairings:
- **New (Blue):** `#5794DD` (Container: `#E3EEFA`, Border: `#BFD7F2`)
- **Approved (Cyan):** `#17A2B8` (Container: `#D1ECF1`, Border: `#A8DAE3`)
- **Tracking (Violet):** `#9872E6` (Container: `#EFE9FB`, Border: `#D3C6F5`)
- **Work In Progress (Amber):** `#FFAC00` (Container: `#FFF3CD`, Border: `#FFE08A`)
- **Solving (Aubergine):** `#714B67` (Container: `#F1E6EE`, Border: `#DFC8D8`)
- **Done (Green):** `#28A745` (Container: `#D4EDDA`, Border: `#B6DFC0`)
- **Rejected / Blocked (Red):** `#DC3545` (Container: `#F8D7DA`, Border: `#F1AEB5`)

### Functional & Surface Neutrals
- **Surface Canvas:** `#F8F9FA`
- **Surface Card/Elevated:** `#FFFFFF`
- **Text Primary:** `#212529`
- **Text Secondary:** `#495057`
- **Text Muted / Placeholder:** `#6C757D` / `#BEC4CB`
- **Hairline Dividers / Subtle Outlines:** `#DEE2E6`

## Typography

The typography uses **Roboto** as the portable stand-in for Odoo's platform system font stack. Its neutral, humanist forms provide clear legibility in dense data environments such as ticket lists, conversation threads, and form views.

### Font Hierarchy & Roles
- **Headlines (`headline-xl`, `headline-lg`, `headline-md`):** Bold 700 with no tracking adjustment, sized from Odoo's heading multipliers (28px, 21px, 18px).
- **Body (`body-lg`, `body-md`, `body-sm`):** Optimized for reading ticket descriptions and conversation messages. Regular 400 weight at the 16px touch base for reading text, 14px for list and form values, and a 1.5 line-height.
- **Labels & Micro-copy (`label-lg`, `label-md`, `label-sm`):** Bold 700 for buttons and badges, medium 500 for field labels and metadata, used in status pills, tags, form labels, and navigation items.

## Layout & Spacing

The layout is built around Odoo's 16px spacer, scaling from mobile to tablet and desktop dispatch dashboards.

### Responsive Breakpoints & Grids
- **Mobile (< 640px):** 4-column fluid layout. Canvas margin: `1rem` (`16px`). Column gutter: `1rem`. Touch target baseline: `48px` minimum height across all operational controls.
- **Tablet (640px – 1024px):** 8-column fluid layout with dynamic split-pane capability (ticket master list on the left, active conversation/action panel on the right). Canvas margin: `1.5rem`. Column gutter: `1.25rem`.
- **Desktop (> 1024px):** 12-column system, max content container fixed at `1440px` centered. Margins: `2rem`. Column gutter: `1.5rem`.

### Spatial Rhythm
- Apply `space-xs` (4px) and `space-sm` (8px) for internal pill padding, label-to-value gap, and compact list metadata.
- Apply `space-md` (16px) for standard component padding, intra-card element spacing, and card stack gaps.
- Apply `space-lg` (24px) and `space-xl` (32px) for sheet offsets, section boundaries, and bottom navigation safe clearance.

## Elevation & Depth

Depth is expressed mainly through **crisp hairline borders (`#DEE2E6`)** and tonal surfaces, with **soft neutral shadows (base `#303030`)** reserved for overlays. This keeps the flat Odoo character while maintaining separation over the pale gray (`#F8F9FA`) backdrop.

### Surface Elevation Hierarchy
- **Level 0 (Canvas Base):** Flat `#F8F9FA`. Houses passive background modules and unselected card gutters.
- **Level 1 (Card & List Item Base):** Pure `#FFFFFF` surface bounded by a `1px` solid outline in `#DEE2E6`. No shadow.
- **Level 2 (Menus, Popovers & Dialogs):** Pure `#FFFFFF`. Shadow: `0px 4px 12px rgba(48, 48, 48, 0.15)`. Border remains hairline `#DEE2E6`.
- **Level 3 (Mobile Bottom Sheet & Context Drawers):** `#FFFFFF` surface anchored at bottom. Shadow: `0px -2px 12px rgba(48, 48, 48, 0.15)`. Top border: `1px solid #DEE2E6`.
- **Level 4 (Floating Action Button & Toast Overlays):** Teal (`#017E84`) for FAB. Shadow: `0px 4px 8px rgba(48, 48, 48, 0.25)`.

## Shapes

The design system maintains a **Slightly Rounded (`1`)** baseline, in keeping with Odoo's near-square corners. Structural cards, inputs, and buttons use a `0.25rem` (`4px`) corner curve, bottom sheets use a larger `1rem` (`16px`) top curve, and actionable meta tags and badges use full pill geometry.

### Corner Radius System
- **Core Elements (Inputs, Cards, Buttons, Action Panels):** `0.1875rem` (3px) for small controls, `0.25rem` (4px) for standard elements, and `0.375rem` (6px) for larger cards.
- **Status Chips & Pills:** Full radius (`9999px`) to emphasize non-structural, interactive state tokens.
- **Bottom Sheet Surface:** Top-left and top-right radii set to `1rem` (16px), wrapping cleanly onto mobile displays.

## Components

### Buttons
- **Primary:** Filled `#017E84` background, `#FFFFFF` bold text, `0.25rem` border radius. Height: `44px` (mobile standard) or `48px` (large). Pressed state darkens by 10%.
- **Secondary:** `#DEE2E6` background with `#212529` label for supporting actions (e.g., "Log note", "Cancel"). Pressed state fills `#CED4DA`.
- **Tonal / Outlined:** Transparent background, `1px solid #DEE2E6`, text `#212529`. Hover/press state fills `#E9ECEF`.

### Chips & Semantic Status Badges
- **Shape & Sizing:** Fully rounded (`rounded-full`), height `24px` to `28px`, horizontal padding `10px`. Text set in `label-sm` or `label-md`.
- **Status Taxonomy Styling:**
  - *New:* `#2D62A3` text, `#E3EEFA` background, `1px solid #BFD7F2`.
  - *Approved:* `#016B88` text, `#D1ECF1` background, `1px solid #A8DAE3`.
  - *Tracking:* `#5B3FB5` text, `#EFE9FB` background, `1px solid #D3C6F5`.
  - *Work In Progress:* `#7A5601` text, `#FFF3CD` background, `1px solid #FFE08A`.
  - *Solving:* `#5B3C53` text, `#F1E6EE` background, `1px solid #DFC8D8`.
  - *Done:* `#006D15` text, `#D4EDDA` background, `1px solid #B6DFC0`.
  - *Rejected:* `#B02A37` text, `#F8D7DA` background, `1px solid #F1AEB5`.

### Cards & Ticket Rows
- **Ticket Card:** `#FFFFFF` background, `4px` border radius, `1px solid #DEE2E6`, padded with `12px`. Left accent border (`3px solid [StatusColor]`) optional for instant visual parsing in high-volume queues.
- **Row List Items:** Divided by subtle `#E9ECEF` rules. Features bold ticket title (`Roboto 700`), meta label (`#6C757D`), and an inline status chip paired with priority stars (`#F3CC00` when filled), a state dot, and a `24px` assignee avatar.

### Form Inputs & Field Labels
- **Behavior & Structure:** 52px height container, transparent background, no outer box, `1px solid #CED4DA` bottom border.
- **Label Mechanics:** Label rests above the value in `label-md`, `#6C757D`. Focus switches the bottom border to `2px solid #017E84`. Required fields use a `#017E84` underline. Invalid state uses a `#DC3545` underline with a `#DC3545` 10% background tint.

### Checkboxes & Radio Controls
- **Checkboxes:** `18px x 18px`, `3px` border radius. Inactive: `1.5px solid #6C757D`. Active: filled `#017E84` with white checkmark glyph.
- **Radio Buttons:** `20px x 20px` circle. Inactive: `1.5px solid #6C757D`. Active: `2px solid #017E84` housing a centered `8px` solid teal core.

### Mobile Bottom Navigation Bar
- **Dimensions & Docking:** Fixed to viewport bottom, height `64px` + safe-area inset. Background `#FFFFFF`, border-top `1px solid #DEE2E6`.
- **Navigation Items:** 4–5 equal slots. Inactive icon & label rendered in `#6C757D`. Active slot highlights with a teal icon (`#017E84`) and bold label.

### Floating Action Button (FAB)
- **Role:** Primary dispatch action (e.g., "+ New Ticket").
- **Style:** 56px circular or extended pill (48px height), background `#017E84`, `#FFFFFF` icon and label, anchored 16px above the bottom navigation bar on the right margin.