# Supernova

<img width="600" height="923" alt="image" src="https://github.com/user-attachments/assets/936102f5-ec3a-4dab-b5eb-101f0af6225d" />


A full-screen Connect IQ data field for the **Garmin Edge 1030 Plus**. Every metric a performance-oriented cyclist watches, in one cockpit-style screen.

---

## What's on screen

▸ **POWER** — current/avg/max watts, IF, %FTP, W/kg, full-width zone bar with current/avg/max markers using the Garmin Connect Z1–Z7 palette

▸ **TIME IN ZONE** — live colored histogram showing your effort distribution as you ride

▸ **HEART RATE** — current/avg/max bpm, %LTHR, aerobic decoupling (drift). Garmin Connect 5-zone bar

▸ **SPEED & CADENCE** — current/avg/max in side-by-side tiles

▸ **TERRAIN** — live grade % (computed from rolling altitude/distance), current altitude, VAM (vertical ascent rate), total ascent/descent. When a course is loaded, shows a **NEXT-waypoint preview** with distance, elevation delta, and average gradient ahead

▸ **FOOTER** — ride duration, TSS, kcal, kJ — the post-ride training summary at a glance

## Design philosophy

Every section earns its space. No decorative chrome. Dense information without overlap. Each big number is identified by its unit (`W`, `BPM`, `km/h`, `rpm`) — no redundant labels. Garmin Connect's zone palettes used everywhere so the on-bike view feels consistent with your post-ride analysis.

## Settings

Configured via the Connect IQ companion app on your phone:

- **FTP** (watts) — Power zones, IF, %FTP, TSS
- **Max HR** (bpm) — HR zones and %Max
- **LTHR** (bpm) — %LTHR
- **Weight** (kg) — W/kg

Defaults: 280 W / 188 bpm / 170 bpm / 70 kg.

## Compatibility

- Edge 1030 Plus (primary target)
- Other Edge devices in the same Connect IQ API tier may work but are untested

## Install

**Once approved on the Connect IQ Store**, install via Garmin Express or the Garmin Connect mobile app and search for "Supernova". (Status: v0.1.0 submitted; review in progress.)

**Sideload** (for testing the latest dev build):
1. Build → see *Develop* below
2. Plug Edge 1030+ into the PC via USB
3. Copy `bin/supernova.prg` → `GARMIN/APPS/` on the device
4. Disconnect, restart the device
5. **Activity Profile → Data Screens → Add Page → Single Field → Connect IQ → Supernova**

## Develop

Prereqs: [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (9.1+), JDK 17, VS Code with the Monkey C extension, a generated developer key.

```bash
# Compile a sideloadable .prg
monkeyc -o bin/supernova.prg \
        -d edge1030plus \
        -f monkey.jungle \
        -y ~/.garmin/developer_key.der

# Compile a store-ready .iq
monkeyc -e -o bin/supernova.iq \
        -f monkey.jungle \
        -y ~/.garmin/developer_key.der -r

# Run in simulator (must be open)
monkeydo bin/supernova.prg edge1030plus
```

## Repo layout

```
manifest.xml                  app metadata, target devices, permissions
monkey.jungle                 build config
source/
  EdgeDataFieldApp.mc         Application skeleton (entry point)
  EdgeDataFieldView.mc        main view — full-screen drawing logic
  ZoneBar.mc                  reusable zone-bar visualization (Power + HR)
  Zones.mc                    Garmin Connect zone palettes + zone math
  DriftTracker.mc             rolling Pw:Hr ratio → aerobic decoupling %
  TerrainTracker.mc           rolling altitude/distance → grade + VAM
  Format.mc                   tiny formatters (duration, fixed, pct)
resources/
  drawables/                  launcher icon
  strings/                    UI strings
  settings/                   companion-app settings + defaults
mockup-v2.html                browser mockup of the final design
STORE_LISTING.md              copy/paste text for the Connect IQ Store submission
PRIVACY.md                    privacy policy (collects nothing)
```

## Privacy

Supernova collects nothing, transmits nothing, and stores only your four local settings on the device. See [PRIVACY.md](./PRIVACY.md).

## License

MIT — see GitHub.

## Known limitations

The Connect IQ API on Edge devices doesn't expose a few cycling-dynamics fields that would be nice to have:

- **L/R balance, Power Phase, PCO, sit/stand detection** — not in `Activity.Info` on Edge 1030+. L/R balance + torque effectiveness + pedal smoothness *are* available via `Toybox.AntPlus.BikePower` (a future addition; the design once tried it before pivoting to Terrain). Power Phase and sit/stand simply aren't exposed.
- **Climb-specific data** (ClimbPro) — only the next-course-waypoint is accessible, used for the NEXT row when a course is loaded.

What we *can* read drives everything the screen shows.
