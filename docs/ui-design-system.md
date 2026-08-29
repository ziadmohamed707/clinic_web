# UI & Design System Documentation

This document describes the design tokens, color palette, typography hierarchy, component theme configs, and responsive utilities in **PhysioOne**.

---

## 🎨 Brand Color Palette (`AppColors`)

Defined in `lib/core/app_colors.dart`, the palette is derived from the official **PhysioOne** warm golden-orange and dark slate brand identity:

```mermaid
style Primary fill:#D18700,color:#fff
style PrimaryDark fill:#B06C00,color:#fff
style PrimaryLight fill:#F4B23A,color:#000
style Secondary fill:#38424B,color:#fff
style SecondaryDark fill:#2B333B,color:#fff
style Background fill:#F9FAFB,color:#000
style Error fill:#E53935,color:#fff

classDef default font-family:sans-serif;

Primary[Primary: #D18700]
PrimaryDark[Primary Dark: #B06C00]
PrimaryLight[Primary Light: #F4B23A]
Secondary[Secondary: #38424B]
SecondaryDark[Secondary Dark: #2B333B]
Background[Background: #F9FAFB]
Error[Status Error: #E53935]
```

### Color Codes Table

| Token Name | Hex Code | Purpose / Usage |
|---|---|---|
| `AppColors.primary` | `#D18700` | Primary brand orange, AppBars, main buttons, active accents |
| `AppColors.primaryDark` | `#B06C00` | Darker orange state for hover/pressed & headlines |
| `AppColors.primaryLight` | `#F4B23A` | Warm golden light accent |
| `AppColors.secondary` | `#38424B` | Dark gray-blue text & secondary UI headers |
| `AppColors.secondaryDark`| `#2B333B` | Dark slate background elements |
| `AppColors.secondaryLight`| `#4F5A63` | Subtitle & border accents |
| `AppColors.background` | `#F9FAFB` | Scaffold background color |
| `AppColors.surface` | `#FFFFFF` | Card & Dialog background |
| `AppColors.error` | `#E53935` | Destructive buttons, error borders, alert badges |

---

## 🔤 Typography System

Configured globally in `lib/main.dart:101-124`:

| Style Name | Font Size | Weight | Color Token |
|---|---|---|---|
| `headlineLarge` | `32px` | Bold (`w700`) | `AppColors.primaryDark` |
| `headlineMedium`| `24px` | SemiBold (`w600`) | `AppColors.primaryDark` |
| `headlineSmall` | `20px` | Medium (`w500`) | `AppColors.primaryDark` |
| `bodyLarge` | `16px` | Normal (`w400`) | `AppColors.black` |
| `bodyMedium` | `14px` | Normal (`w400`) | `AppColors.black` |
| `labelLarge` | `14px` | Medium (`w500`) | `AppColors.white` |

---

## 🖼️ Component Design Tokens

- **Card Theme**: Rounded corners with `BorderRadius.circular(12)` and elevation `2`.
- **Button Theme**: Rounded corners with `BorderRadius.circular(8)`, padding `symmetric(h: 20, v: 12)`.
- **Input Fields**: Outline borders with teal/golden focus states (`#B2DFDB` border, `AppColors.primary` focused width 2).
- **Glassmorphic Navigation Drawer**: `BackdropFilter` with `sigmaX: 10, sigmaY: 10`, linear gradients, and radial glowing logo container.
