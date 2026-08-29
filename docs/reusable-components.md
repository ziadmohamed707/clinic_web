# Reusable Components Documentation

This document describes the shared UI components, widgets, dialogs, and helper components across **PhysioOne**.

---

## 🧩 Reusable Widgets Index

### 1. `StateCard` (`lib/widgets/state_card.dart`)
- **Purpose**: Displays key metric stat cards on dashboards (e.g. Total Appointments, Available Slots, Total Clients, Cancellations).
- **Parameters**: `title`, `value`, `icon`, `color`, `subtitle`.
- **Styling**: Card layout with shadow, icon container with background tint matching metric theme.

---

### 2. `buildModernSidebarItem` (`lib/ui/ScheduleGridPade/widget/buildModernSidebarItem.dart`)
- **Purpose**: Renders glassmorphic animated menu items inside the application navigation drawer.
- **Parameters**: `icon`, `title`, `subtitle`, `gradient`, `onTap`.
- **Behavior**: Scale transformation and gradient glow on hover.

---

### 3. `buildStatsCard` (`lib/ui/ScheduleGridPade/widget/buildStatsCard.dart`)
- **Purpose**: Specialized compact statistics pill widget used at the top of the schedule grid header.
- **Parameters**: `title`, `value`, `icon`, `gradientColors`.

---

### 4. `EditCellDialog` (`lib/helper/edit_cell.dart`)
- **Purpose**: Complex interactive dialog allowing staff to book, edit, or cancel appointments directly from the schedule matrix.
- **Features**: Patient selection dropdown, doctor dropdown, time slot selection, service type selection, follow-up package decrement options, and direct WhatsApp notification launcher.

---

### 5. `EditClientDialog` (`lib/helper/edit_client.dart`)
- **Purpose**: Modal form for updating client profile details, phone numbers, notes, and package allocations.
