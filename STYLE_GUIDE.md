# SkyNetCMS Style Guide

This document defines the visual identity, color system, typography, and component styling for SkyNetCMS. All admin interface components should follow these guidelines for consistency.

---

## 1. Brand Identity

### Name & Tagline
- **Product Name**: SkyNetCMS
- **Tagline**: AI-Powered Conversational CMS
- **Personality**: Techy, modern, powerful yet approachable

### Voice & Tone
- Professional but not corporate
- Technical but accessible
- Confident but not intimidating

---

## 2. Logo

### Concept
The SkyNetCMS logo combines a **hexagonal neural network icon** with styled text. The hexagon grid represents AI/interconnected systems, while the network nodes suggest intelligence and connectivity.

### Icon Description
- 3-4 hexagons arranged in a cluster pattern
- Connected by lines (neural network style)
- Small circular nodes at connection points
- Rendered in accent cyan color

### Text Treatment
- "SkyNet" in primary white (`#ffffff`)
- "CMS" in accent cyan (`#00d4ff`)
- Font weight: 700 (bold)
- Letter spacing: -0.5px for "SkyNet", normal for "CMS"

### Size Variants
| Context | Icon Size | Text Size | Usage |
|---------|-----------|-----------|-------|
| Favicon | 16-32px | N/A | Browser tab |
| Toolbar | 24px | 14px | Admin header |
| Login/Setup | 40px | 28px | Registration page |
| Large Display | 64px+ | 36px+ | Marketing, splash |

### Clear Space
Maintain minimum padding equal to the icon height around the logo.

### File Locations
```
nginx/assets/logo.svg           # Full logo (icon + text)
nginx/assets/logo-icon.svg      # Icon only
nginx/assets/favicon.svg        # Favicon version
```

---

## 3. Color System

### CSS Custom Properties

All colors are defined as CSS custom properties for easy theming and consistency.

```css
:root {
  /* ===== Background Colors ===== */
  --sn-bg-primary:     #0f0f1a;    /* Darkest - page background */
  --sn-bg-secondary:   #1a1a2e;    /* Panels, cards, containers */
  --sn-bg-tertiary:    #16213e;    /* Elevated surfaces, hover states */
  --sn-bg-elevated:    #1e2a4a;    /* Modals, dropdowns */
  
  /* ===== Accent Colors ===== */
  --sn-accent:         #00d4ff;    /* Primary accent - buttons, links, highlights */
  --sn-accent-hover:   #33ddff;    /* Accent hover state */
  --sn-accent-active:  #00a8cc;    /* Accent active/pressed state */
  --sn-accent-muted:   #0099b8;    /* Secondary accent uses */
  --sn-accent-subtle:  rgba(0, 212, 255, 0.1);  /* Accent backgrounds */
  
  /* ===== Text Colors ===== */
  --sn-text-primary:   #ffffff;    /* Primary text on dark backgrounds */
  --sn-text-secondary: #a0aec0;    /* Secondary/supporting text */
  --sn-text-muted:     #718096;    /* Muted/disabled text */
  --sn-text-inverse:   #1a1a2e;    /* Text on light backgrounds */
  
  /* ===== Border Colors ===== */
  --sn-border:         #2a2a4a;    /* Default borders */
  --sn-border-hover:   #3a3a5a;    /* Border hover state */
  --sn-border-focus:   #00d4ff;    /* Focus ring color */
  
  /* ===== Status Colors ===== */
  --sn-success:        #48bb78;    /* Success states */
  --sn-success-bg:     rgba(72, 187, 120, 0.1);
  --sn-error:          #f56565;    /* Error states */
  --sn-error-bg:       rgba(245, 101, 101, 0.1);
  --sn-warning:        #ed8936;    /* Warning states */
  --sn-warning-bg:     rgba(237, 137, 54, 0.1);
  --sn-info:           #4299e1;    /* Info states */
  --sn-info-bg:        rgba(66, 153, 225, 0.1);
  
  /* ===== Shadow Colors ===== */
  --sn-shadow-sm:      0 1px 2px rgba(0, 0, 0, 0.3);
  --sn-shadow-md:      0 4px 6px rgba(0, 0, 0, 0.3);
  --sn-shadow-lg:      0 8px 16px rgba(0, 0, 0, 0.4);
  --sn-shadow-xl:      0 16px 32px rgba(0, 0, 0, 0.5);
  --sn-shadow-glow:    0 0 20px rgba(0, 212, 255, 0.3);  /* Accent glow effect */
}
```

### Color Usage Guidelines

| Element | Property | Variable |
|---------|----------|----------|
| Page background | `background` | `--sn-bg-primary` |
| Cards/panels | `background` | `--sn-bg-secondary` |
| Floating window | `background` | `--sn-bg-secondary` |
| Window header | `background` | `--sn-bg-secondary` |
| Primary buttons | `background` | `--sn-accent` |
| Button text | `color` | `--sn-text-primary` |
| Body text | `color` | `--sn-text-primary` |
| Labels/captions | `color` | `--sn-text-secondary` |
| Disabled text | `color` | `--sn-text-muted` |
| Input borders | `border-color` | `--sn-border` |
| Input focus | `border-color` | `--sn-border-focus` |

### Gradient Backgrounds

For special surfaces (login page, hero sections):

```css
/* Primary gradient - diagonal dark blue */
background: linear-gradient(135deg, #0f0f1a 0%, #16213e 50%, #0f3460 100%);

/* Accent gradient - for primary buttons */
background: linear-gradient(135deg, #00d4ff 0%, #0099b8 100%);

/* Subtle mesh gradient - for backgrounds */
background: 
  radial-gradient(at 20% 80%, rgba(0, 212, 255, 0.08) 0%, transparent 50%),
  radial-gradient(at 80% 20%, rgba(0, 212, 255, 0.05) 0%, transparent 50%),
  #0f0f1a;
```

---

## 4. Typography

### Font Stack

```css
:root {
  --sn-font-sans: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  --sn-font-mono: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Mono', 'Droid Sans Mono', monospace;
}
```

### Font Sizes

```css
:root {
  --sn-text-xs:   11px;   /* Tiny labels, badges */
  --sn-text-sm:   13px;   /* Small text, captions */
  --sn-text-base: 14px;   /* Body text (default) */
  --sn-text-lg:   16px;   /* Large body, input text */
  --sn-text-xl:   20px;   /* Small headings */
  --sn-text-2xl:  24px;   /* Section headings */
  --sn-text-3xl:  28px;   /* Page titles */
  --sn-text-4xl:  36px;   /* Hero headings */
}
```

### Font Weights

```css
:root {
  --sn-font-normal:   400;  /* Body text */
  --sn-font-medium:   500;  /* Labels, emphasized text */
  --sn-font-semibold: 600;  /* Buttons, subheadings */
  --sn-font-bold:     700;  /* Headings, logo */
}
```

### Line Heights

```css
:root {
  --sn-leading-tight:  1.25;  /* Headings */
  --sn-leading-normal: 1.5;   /* Body text */
  --sn-leading-loose:  1.75;  /* Readable paragraphs */
}
```

### Typography Patterns

```css
/* Page title */
.sn-title {
  font-size: var(--sn-text-3xl);
  font-weight: var(--sn-font-bold);
  color: var(--sn-text-primary);
  letter-spacing: -0.5px;
}

/* Section heading */
.sn-heading {
  font-size: var(--sn-text-xl);
  font-weight: var(--sn-font-semibold);
  color: var(--sn-text-primary);
}

/* Body text */
.sn-body {
  font-size: var(--sn-text-base);
  font-weight: var(--sn-font-normal);
  color: var(--sn-text-primary);
  line-height: var(--sn-leading-normal);
}

/* Caption/label */
.sn-caption {
  font-size: var(--sn-text-sm);
  font-weight: var(--sn-font-medium);
  color: var(--sn-text-secondary);
}
```

---

## 5. Spacing & Sizing

### Spacing Scale

```css
:root {
  --sn-space-1:  4px;
  --sn-space-2:  8px;
  --sn-space-3:  12px;
  --sn-space-4:  16px;
  --sn-space-5:  20px;
  --sn-space-6:  24px;
  --sn-space-8:  32px;
  --sn-space-10: 40px;
  --sn-space-12: 48px;
  --sn-space-16: 64px;
}
```

### Border Radius

```css
:root {
  --sn-radius-sm:   4px;   /* Small elements, badges */
  --sn-radius-md:   8px;   /* Buttons, inputs, cards */
  --sn-radius-lg:   12px;  /* Modals, large cards */
  --sn-radius-xl:   16px;  /* Large containers */
  --sn-radius-full: 9999px; /* Pills, avatars */
}
```

---

## 6. Component Styles

### Buttons

#### Primary Button
```css
.sn-btn-primary {
  background: linear-gradient(135deg, var(--sn-accent) 0%, var(--sn-accent-active) 100%);
  color: var(--sn-text-inverse);
  border: none;
  padding: 12px 20px;
  border-radius: var(--sn-radius-md);
  font-size: var(--sn-text-base);
  font-weight: var(--sn-font-semibold);
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.sn-btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: var(--sn-shadow-glow);
}

.sn-btn-primary:active {
  transform: translateY(0);
}

.sn-btn-primary:disabled {
  background: var(--sn-text-muted);
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}
```

#### Secondary Button
```css
.sn-btn-secondary {
  background: transparent;
  color: var(--sn-text-secondary);
  border: 1px solid var(--sn-border);
  padding: 12px 20px;
  border-radius: var(--sn-radius-md);
  font-size: var(--sn-text-base);
  font-weight: var(--sn-font-medium);
  cursor: pointer;
  transition: all 0.2s;
}

.sn-btn-secondary:hover {
  background: var(--sn-bg-tertiary);
  color: var(--sn-text-primary);
  border-color: var(--sn-border-hover);
}
```

#### Ghost Button (Toolbar)
```css
.sn-btn-ghost {
  background: transparent;
  color: var(--sn-text-secondary);
  border: 1px solid var(--sn-border);
  padding: 6px 12px;
  border-radius: var(--sn-radius-sm);
  font-size: var(--sn-text-sm);
  cursor: pointer;
  transition: all 0.2s;
}

.sn-btn-ghost:hover {
  background: var(--sn-bg-tertiary);
  color: var(--sn-text-primary);
  border-color: var(--sn-border-hover);
}
```

### Input Fields

```css
.sn-input {
  width: 100%;
  padding: 14px 16px;
  background: var(--sn-bg-primary);
  color: var(--sn-text-primary);
  border: 2px solid var(--sn-border);
  border-radius: var(--sn-radius-md);
  font-size: var(--sn-text-lg);
  transition: border-color 0.2s, box-shadow 0.2s;
}

.sn-input:focus {
  outline: none;
  border-color: var(--sn-border-focus);
  box-shadow: 0 0 0 3px var(--sn-accent-subtle);
}

.sn-input::placeholder {
  color: var(--sn-text-muted);
}

.sn-input.error {
  border-color: var(--sn-error);
}
```

### Cards/Panels

```css
.sn-card {
  background: var(--sn-bg-secondary);
  border-radius: var(--sn-radius-lg);
  padding: var(--sn-space-6);
  box-shadow: var(--sn-shadow-lg);
}
```

### Floating Window (Admin Dashboard)

```css
/* Window container */
#si-window {
  background: var(--sn-bg-secondary);
  border-radius: var(--sn-radius-lg);
  box-shadow: var(--sn-shadow-xl);
  border: 1px solid var(--sn-border);
}

/* Window header */
#si-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--sn-space-2) var(--sn-space-3);
  background: var(--sn-bg-secondary);
  border-bottom: 1px solid var(--sn-border);
  height: 40px;
  cursor: move;
}

/* Header title */
.sn-toolbar-title {
  color: var(--sn-text-primary);
  font-size: var(--sn-text-sm);
  font-weight: var(--sn-font-semibold);
  display: flex;
  align-items: center;
  gap: var(--sn-space-2);
  user-select: none;
}

/* Header title accent */
.sn-toolbar-title .accent {
  color: var(--sn-accent);
}
```

### Status Messages

```css
/* Success message */
.sn-alert-success {
  background: var(--sn-success-bg);
  border: 1px solid var(--sn-success);
  color: var(--sn-success);
  padding: var(--sn-space-3) var(--sn-space-4);
  border-radius: var(--sn-radius-md);
  font-size: var(--sn-text-sm);
}

/* Error message */
.sn-alert-error {
  background: var(--sn-error-bg);
  border: 1px solid var(--sn-error);
  color: var(--sn-error);
  padding: var(--sn-space-3) var(--sn-space-4);
  border-radius: var(--sn-radius-md);
  font-size: var(--sn-text-sm);
}

/* Warning message */
.sn-alert-warning {
  background: var(--sn-warning-bg);
  border: 1px solid var(--sn-warning);
  color: var(--sn-warning);
  padding: var(--sn-space-3) var(--sn-space-4);
  border-radius: var(--sn-radius-md);
  font-size: var(--sn-text-sm);
}
```

---

## 7. Implementation Notes

### Adding Styles to a Page

Include the CSS custom properties at the top of your `<style>` block or in a shared stylesheet:

```html
<style>
  :root {
    /* Copy all CSS custom properties from Section 3-5 */
  }
  
  /* Your component styles using the variables */
</style>
```

### Customization

To create a custom theme, override the CSS custom properties:

```css
/* Example: Light theme override */
:root.light-theme {
  --sn-bg-primary:   #f7fafc;
  --sn-bg-secondary: #ffffff;
  --sn-text-primary: #1a202c;
  /* ... etc */
}
```

### Logo Replacement

To use a custom logo:

1. Replace the SVG files in `nginx/assets/`
2. Maintain the same filenames
3. Ensure SVG viewBox is appropriate for the size variants
4. Use `currentColor` in SVG for text that should inherit color

### Accessibility Notes

- Ensure color contrast meets WCAG 2.1 AA standards (4.5:1 for text)
- Focus states should be visible (using `--sn-border-focus`)
- Interactive elements should have hover/active states
- Use semantic HTML elements where possible

---

## 8. Migration from v0 (Pre-Style Guide)

The following changes are made from the original ad-hoc styling:

| Element | Old Value | New Value | Notes |
|---------|-----------|-----------|-------|
| Primary accent | `#e94560` (red) | `#00d4ff` (cyan) | More techy, AI-like |
| Accent hover | `#c73659` | `#33ddff` | Lighter on hover |
| Button gradient | Red gradient | Cyan gradient | Updated accent |
| Logo text | Red "Net" | Cyan "CMS" | "SkyNet" white, "CMS" cyan |

Files to update:
- `nginx/admin-dashboard/index.html`
- `nginx/admin-registration/index.html`
- `templates/default/src/index.html` (welcome page)

---

## 9. Future Considerations

### Planned Enhancements
- Dark/light theme toggle
- User-customizable accent colors
- High contrast mode for accessibility
- Reduced motion preference support

### Not In Scope (MVP)
- Custom font loading (system fonts only)
- Complex animations
- Theme marketplace

---

*Last Updated: 2026-01-20*
*Version: 1.0*
