# Connect IQ Store Submission — Supernova

Upload URL: **https://apps.garmin.com/developer/upload**

## Build asset

```
C:\Users\miche\garmin\supernova\bin\supernova.iq
```

Upload this single file.

## Form fields — copy/paste

### App Name
```
Supernova
```

### Summary (max ~80 chars)
```
Cockpit-style data screen for Edge 1030+ — power, HR, zones, terrain in one view
```

### Description (4000 char limit)
```
SUPERNOVA — A full-screen Connect IQ data field for the Garmin Edge 1030 Plus.

Every metric a performance-oriented cyclist watches, in one cockpit-style screen.

▸ POWER — current/avg/max watts, IF, %FTP, W/kg, full-width zone bar with current/avg/max markers (Garmin Connect Z1–Z7 palette)

▸ TIME IN ZONE — live colored histogram showing your effort distribution as you ride

▸ HEART RATE — current/avg/max bpm, %LTHR, aerobic decoupling (drift), Garmin Connect 5-zone bar with the same marker pattern

▸ SPEED & CADENCE — current/avg/max for both, in clean side-by-side tiles

▸ TERRAIN — live grade % (computed from rolling altitude/distance), current altitude, VAM (vertical ascent rate), total ascent/descent. When a course is loaded, shows a NEXT-waypoint preview (distance + elevation delta + average gradient ahead)

▸ FOOTER — ride duration, TSS, kcal, kJ — the post-ride training summary at a glance

Design philosophy: every section earns its space. No decorative chrome. Dense information density without overlap. Each big number is identified by its unit (W, BPM, km/h, rpm) — no redundant labels.

Settings (configure via the Connect IQ companion app):
• FTP (watts) — for Power zones, IF, %FTP, TSS
• Max HR (bpm) — for HR zones and %Max
• LTHR (bpm) — for %LTHR
• Weight (kg) — for W/kg

Compatible with the Garmin Edge 1030 Plus.

Open source: https://github.com/michelkluger/supernova
```

### Category
- **Type**: Data Field
- **Category**: Sports & Recreation
- **Tags**: cycling, training, power, FTP, climbing, performance

### Price
**Free**

### Version
```
0.1.0
```

### What's New (changelog for first release)
```
First release.

• Full-screen cockpit data screen for Edge 1030+
• Power section with Z1–Z7 zone bar, IF, %FTP, W/kg
• Live time-in-zone histogram
• Heart rate with %LTHR and aerobic-decoupling drift
• Speed + Cadence tiles
• Terrain: live grade, altitude, VAM, total ascent/descent
• Course-aware ETA and next-waypoint preview
• 4-cell ride summary footer (Ride / TSS / kcal / kJ)
```

### Supported devices
- Edge 1030 Plus

### Permissions justification
- **UserProfile** — used to read body weight as a fallback for W/kg calculation when not set in app settings

### Privacy policy URL
If asked: this app collects no data and makes no network requests. Either:
- Point to the GitHub README: `https://github.com/michelkluger/supernova#privacy`
- Or add a short PRIVACY.md file (we can do this if needed)

## Screenshots (required: 1–5 PNGs at 282×470 or 564×940)

Capture from the running simulator. **In the CIQ simulator window: File → Capture Image** (or hit the screenshot keybind), save the PNGs.

Suggested shots:
1. Full screen at a high-power moment (zone bar showing Z4 highlighted)
2. Mid-ride with TIZ histogram showing variety (multiple colored segments)
3. On a climb with positive grade + altitude flowing
4. Maybe one with a course loaded showing the NEXT row populated

Place captured PNGs in `screenshots/` here; upload them one by one in the form.

## Review process

1. Upload `supernova.iq` + screenshots + fill the form
2. Garmin reviews (typically 1–5 business days)
3. May come back with revision requests (most common: app permission text, screenshot quality, broken on specific firmware)
4. Once approved, listing goes live at `https://apps.garmin.com/en-US/apps/<your-app-uuid>`
5. Users install via Garmin Express or the Connect mobile app
