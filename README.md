# Supernova

A custom full-screen Connect IQ data field for the Garmin Edge 1030 Plus — every metric a performance-oriented cyclist watches, in one cockpit-style screen. Design lives in `../mockup-v2.html`.

**Sections:** Status · Progress · Power (zone bar + IF/%FTP/W·kg⁻¹/L·R) · Time in Zone · Heart Rate (zone bar + %LTHR/Drift) · Speed + Cadence · Cycling Dynamics (Power Phase + sit/stand) · Ride summary footer (TSS/kcal/Load).

## Setup (one time)

1. **Garmin developer account** — sign up at https://developer.garmin.com (free)
2. **Connect IQ SDK Manager** — download from https://developer.garmin.com/connect-iq/sdk/
   - Install the latest SDK
   - In the SDK Manager, install the **Edge 1030 Plus** device profile (and **Edge 1030 Plus Simulator**)
3. **VS Code + Monkey C extension** — install from VS Code marketplace
4. **Generate a developer key**:
   - In VS Code: `Ctrl+Shift+P` → `Monkey C: Generate a Developer Key`
   - Save it somewhere stable, e.g. `C:\Users\miche\.garmin\developer_key.der`
   - In VS Code settings, point `monkeyC.developerKeyPath` at it

## Build & test

In VS Code with this folder open:

- `Ctrl+Shift+P` → **Monkey C: Build for Device** (compiles)
- `Ctrl+Shift+P` → **Monkey C: Run No Live Review** (launches simulator with Edge 1030+)

In the simulator:

- **File → Simulate Activity** → choose a recorded `.fit` file (or use the built-in simulated activity)
- The data field shows on a dedicated screen — switch to it via the simulator's screen navigation

## Sideload to the actual device

1. Build → produces `bin/EdgeDataFieldApp.prg`
2. Connect Edge 1030+ via USB
3. Copy `EdgeDataFieldApp.prg` to `GARMIN/APPS/` on the device
4. Disconnect, restart the device
5. On the Edge: **Activity Profile → Data Screens → Add Page → Single Field → Connect IQ → Edge 1030+ DataField**

## Settings (Connect IQ companion app)

After install, configure on phone:

- **FTP** — your functional threshold power in watts (used for Power zones, IF, %FTP, TSS)
- **Max HR** — used for HR zones and %Max
- **LTHR** — Lactate Threshold HR, used for %LTHR
- **Weight** — kg, used for W/kg

Defaults: FTP 280, Max HR 188, LTHR 170, Weight 70 kg. Update on day 1.

## What's in here

```
manifest.xml                  app metadata, target devices, permissions
monkey.jungle                 build config
source/
  EdgeDataFieldApp.mc         Application skeleton (entry point)
  EdgeDataFieldView.mc        main view — full-screen drawing logic
  ZoneBar.mc                  reusable zone-bar visualization
  PedalCircle.mc              power phase arc rendering
  Zones.mc                    Garmin Connect zone palettes + power/HR zone math
  Format.mc                   tiny formatters (duration, fixed, pct)
resources/
  strings/strings.xml         all UI strings
  settings/settings.xml       companion-app settings UI (FTP, LTHR…)
  settings/properties.xml     default values
```

## What works in v0.1

- Status bar (time, GPS/ANT dots, battery)
- Progress bar (distance, ETA placeholder)
- Power section (current, ø/▲, IF, %FTP, W/kg, zone bar)
- Time-in-zone histogram (live accumulator)
- HR section (current, ø/▲, %LTHR, zone bar)
- Speed + Cadence tiles
- Pedal Dynamics (PP arcs, PPP, PCO, sit/stand bars) — requires dual-side power meter
- Footer (Ride / TSS / Kcal / Load placeholder)

## What's stubbed for v1.0

- **Course-aware progress** — `totalKm` is hardcoded to 48 km. Read from `Activity.Info.distanceToDestination` once a course is loaded.
- **ETA** — currently shows `--:--`. Compute from `distanceToDestination / averageSpeed` and add to current time.
- **Load** — Garmin's "Training Load" is a derived metric. Read from `UserProfile.UserProfile` if exposed, else show `--`.
- **Drift (HR)** — needs a rolling Pw:Hr ratio comparison vs the first 10 min. Stubbed `+0%`.
- **Sit/stand silhouette icons** — currently colored dots; replace with proper SVG-derived bitmap.
- **Custom font** — currently uses `FONT_NUMBER_MEDIUM` system font for the big Power number. To match Oxanium aesthetic, compile a `.fnt` from the TTF and reference via `Graphics.FONT_*` resource.

## Design notes

- Layout coords mirror the v2 mockup's flex-weighted heights (Power 110px, TIZ 28px, HR 78px, Tiles 65px, Pedal 121px on the 470px screen).
- Color constants in `EdgeDataFieldView.mc` match the mockup's CSS palette exactly.
- Avoid allocations in `compute()` and `onUpdate()` — they run at 1 Hz and CPU-throttling kicks in past ~30 ms per draw.
- Cycling Dynamics fields are nullable; always check `info has :leftPowerPhase` before reading.
