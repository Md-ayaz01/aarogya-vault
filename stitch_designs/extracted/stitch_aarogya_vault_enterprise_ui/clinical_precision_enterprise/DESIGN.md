---
name: Clinical Precision Enterprise
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3d4a44'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6c7a74'
  outline-variant: '#bccac2'
  surface-tint: '#006b53'
  primary: '#006b53'
  on-primary: '#ffffff'
  primary-container: '#00a884'
  on-primary-container: '#003427'
  inverse-primary: '#59dcb5'
  secondary: '#545f73'
  on-secondary: '#ffffff'
  secondary-container: '#d5e0f8'
  on-secondary-container: '#586377'
  tertiary: '#006591'
  on-tertiary: '#ffffff'
  tertiary-container: '#009ee0'
  on-tertiary-container: '#003149'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#79f9d0'
  primary-fixed-dim: '#59dcb5'
  on-primary-fixed: '#002117'
  on-primary-fixed-variant: '#00513e'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#c9e6ff'
  tertiary-fixed-dim: '#89ceff'
  on-tertiary-fixed: '#001e2f'
  on-tertiary-fixed-variant: '#004c6e'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  title-sm:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  data-tabular:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 24px
  gutter: 16px
  density-high: 8px
  density-ultra: 4px
  sidebar-width: 260px
  inspector-width: 320px
---

## Brand & Style
This design system is engineered for the high-stakes environment of hospital administration. The brand personality is authoritative, ultra-reliable, and highly efficient. The visual style follows a **Corporate / Modern** movement with a heavy emphasis on information density and functional clarity. 

The aesthetic prioritizes scanability over decorative elements, utilizing a "Utility-First" approach. It features subtle tonal layering to manage complex information hierarchies without visual fatigue. The emotional response is one of calm control and unwavering accuracy, ensuring that administrators can process vast amounts of medical and logistical data with minimal cognitive load.

## Colors
The palette is anchored by the primary green (#00A884), representing health and operational "go" states. The secondary Slate color provides the professional grounding necessary for enterprise software.

**Color Modes:**
- **Light Mode:** Optimized for high-glare environments like well-lit nursing stations. Uses a "Cool Gray" foundation to reduce eye strain.
- **Dark Mode:** Designed for low-light monitoring centers, utilizing deep navy tones (#0F172A) instead of pure black to maintain legible contrast ratios.

**Status System:**
Semantic colors are strictly enforced for medical triaging and administrative status. 
- **Critical:** High-visibility red for urgent patient or system alerts.
- **Stable:** Muted emerald, distinct from the primary brand green.
- **Pending:** Amber for items requiring review or in-progress workflows.

## Typography
The typographic system utilizes **Hanken Grotesk** for structural elements and headers to provide a modern, clean signature. **Inter** is used for all data-heavy UI, body text, and labels due to its exceptional legibility at small sizes and extensive OpenType features.

For the Hospital Admin Portal, tabular figures (`tnum`) are enabled by default for all numerical data in tables to ensure columns of figures align perfectly for easy comparison. The default body size is set to 14px to maximize information density while remaining within accessibility guidelines for enterprise desktop applications.

## Layout & Spacing
This design system employs a **Fluid Grid** model with a 4px baseline rhythm. The layout is structured as a **Multi-Pane Dashboard**:
1.  **Global Navigation:** Collapsible left sidebar (260px).
2.  **Contextual Workspace:** Central fluid area for data tables and charts.
3.  **Inspector/Detail Pane:** Right-aligned slide-out (320px) for deep-dive patient or record info.

**High-Density Rules:**
In data-heavy views, vertical cell padding is reduced to 8px (`density-high`) or 4px (`density-ultra`) to minimize scrolling. Margins between logical sections remain generous (24px) to prevent the UI from feeling claustrophobic.

## Elevation & Depth
Depth is communicated through **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows. This maintains a "flat-plus" aesthetic that feels clinical and precise.

- **Level 0 (Background):** Used for the main application canvas.
- **Level 1 (Card/Surface):** Used for white (or dark navy) containers. Features a 1px border (#E2E8F0 in light mode).
- **Level 2 (Active/Hover):** Subtle ambient shadow (4px blur, 2% opacity) used only for interactive elements like draggable widgets or open dropdowns.
- **Dividers:** Used extensively in tables. 1px solid lines with high-contrast ratios for accessibility.

## Shapes
A **Soft** shape language (4px radius) is applied across all standard components. This provides a professional, "software-engineered" feel that is more approachable than sharp corners but more space-efficient than highly rounded or pill-shaped designs. Buttons and input fields use the `rounded-sm` (4px) setting, while main dashboard cards use `rounded-lg` (8px).

## Components

### Data Tables
- **Header:** Sticky headers with a background tint and bold `label-caps` text.
- **Rows:** Zebra striping enabled for long-form data. Hover states use a 5% primary color tint.
- **Cells:** Vertical alignment is centered. Numeric data is right-aligned.

### Status Indicators (Badges)
- **Style:** Small, subtle background tint with high-contrast text. 
- **Critical:** Red background (10% opacity) with Bold Red text + Warning Icon.
- **Stable:** Green background (10% opacity) with Green text.

### Buttons
- **Primary:** Solid #00A884 with white text.
- **Secondary:** Transparent background with 1px Slate border.
- **Action Density:** Icons-only buttons (Ghost style) used in table rows for editing/viewing to save horizontal space.

### Multi-Pane Navigation
- **Sidebar:** Dark secondary color in Light mode for clear separation. Active states indicated by a 4px primary green left-border "accent" and a subtle background highlight.

### Input Fields
- **State:** Default 1px border. Focus state uses a 2px primary green ring.
- **Accessibility:** Label is always visible above the field; placeholder text never replaces the label.