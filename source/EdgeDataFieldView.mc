using Toybox.Activity;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.UserProfile;
using Toybox.WatchUi;

// ─── EdgeDataFieldView ───
// Full-screen Connect IQ data field for Edge 1030 Plus (282×470 px).
// Layout mirrors mockup-v2.html:
//   STATUS (18px) · PROGRESS (16px) · POWER · TIZ · HR · SPEED|CADENCE · PEDAL DYN · FOOTER (34px)
class EdgeDataFieldView extends WatchUi.DataField {

    // ─── colors ───
    const COL_BG        = 0x0c0c10;
    const COL_TEXT      = 0xf4f4f7;
    const COL_DIM       = 0x9b9ba4;
    const COL_MUTED     = 0x5e5e68;
    const COL_LINE      = 0x1c1c20;
    const COL_AVG       = 0xef4444;
    const COL_MAX       = 0xffffff;
    const COL_GOLD      = 0xfbbf24;
    const COL_CAL       = 0xfb923c;
    const COL_GREEN     = 0x22c55e;
    const COL_LEG_L     = 0x84cc16;
    const COL_LEG_R     = 0x60a5fa;

    // ─── settings (refreshed each onUpdate) ───
    var ftp = 280;
    var maxHR = 188;
    var lthr = 170;
    var weight = 70;

    // ─── live values cached in compute() ───
    var power, avgPower, maxPower;
    var hr, avgHR, maxHR_v;
    var speed, avgSpeed, maxSpeed;     // m/s — convert to km/h on draw
    var cadence, avgCadence, maxCadence;
    var distance;                       // metres
    var elapsedTime;                    // seconds
    var calories;                       // kcal
    var distanceToDest;                 // metres remaining on loaded course (null if no course)
    var timeToDest;                     // seconds remaining (null if no course)
    var altitude;                       // metres above sea level
    var totalAscent;                    // total ascent meters this activity
    var totalDescent;                   // total descent meters
    var distanceToNextPoint;            // metres to next course waypoint
    var elevationAtNextPoint;           // altitude at next course waypoint
    var leftBalance;                    // % left
    var leftPP, leftPPP, leftPCO;
    var rightPP, rightPPP, rightPCO;
    var seatedTime, standingTime;
    // Time-in-zone (Power, 7 zones) — accumulated seconds per zone
    var tizPower = [0, 0, 0, 0, 0, 0, 0];
    var lastSampleTime = null;


    function initialize() {
        DataField.initialize();
        _readSettings();
        DriftTracker.reset();
        TerrainTracker.reset();
    }

    function _readSettings() {
        ftp    = _getProp("FTP", 280);
        maxHR  = _getProp("MaxHR", 188);
        lthr   = _getProp("LTHR", 170);
        weight = _getProp("Weight", 70);

        // UserProfile fallback: only weight is a direct field on the Profile type.
        // Max HR isn't exposed as a single property — leave it user-set via settings.
        var prof = UserProfile.getProfile();
        if (prof != null && weight == 70 && prof.weight != null) {
            weight = prof.weight / 1000.0;
        }
    }

    function _getProp(key, fallback) {
        var v = Application.Properties.getValue(key);
        return (v != null) ? v : fallback;
    }

    // ─── compute() ───
    // Called once per second when activity is recording. Cache values, update accumulators.
    function compute(info) {
        if (info == null) { return; }

        power      = info.currentPower;
        avgPower   = info.averagePower;
        maxPower   = info.maxPower;

        hr         = info.currentHeartRate;
        avgHR      = info.averageHeartRate;
        maxHR_v    = info.maxHeartRate;

        speed      = info.currentSpeed;
        avgSpeed   = info.averageSpeed;
        maxSpeed   = info.maxSpeed;

        cadence    = info.currentCadence;
        avgCadence = info.averageCadence;
        maxCadence = info.maxCadence;

        distance     = info.elapsedDistance;
        elapsedTime  = info.elapsedTime != null ? info.elapsedTime / 1000 : null;
        calories     = info.calories;

        // Course-aware progress (populated when user loaded a course / navigation target)
        if (info has :distanceToDestination) { distanceToDest = info.distanceToDestination; }
        if (info has :timeToDestination)     { timeToDest     = info.timeToDestination; }

        // Terrain
        if (info has :altitude)              { altitude              = info.altitude; }
        if (info has :totalAscent)           { totalAscent           = info.totalAscent; }
        if (info has :totalDescent)          { totalDescent          = info.totalDescent; }
        if (info has :distanceToNextPoint)   { distanceToNextPoint   = info.distanceToNextPoint; }
        if (info has :elevationAtNextPoint)  { elevationAtNextPoint  = info.elevationAtNextPoint; }

        // Roll the trackers
        DriftTracker.tick(power, hr);
        if (elapsedTime != null) {
            TerrainTracker.tick(altitude, distance, elapsedTime);
        }

        // Cycling Dynamics — only present with dual-side power meter
        // Note: Activity.Info doesn't expose L/R balance directly on the Edge 1030+ SDK 9 surface.
        // For v0.1 we default to 50/50; real balance will come via FIT message parsing in a later iteration.
        leftBalance = 50;
        if (info has :leftPowerPhase && info.leftPowerPhase != null) {
            leftPP = info.leftPowerPhase;            // [start, end] in degrees
        }
        if (info has :leftPowerPhasePeak && info.leftPowerPhasePeak != null) {
            leftPPP = info.leftPowerPhasePeak;
        }
        if (info has :leftPlatformCenterOffset) {
            leftPCO = info.leftPlatformCenterOffset;
        }
        if (info has :rightPowerPhase && info.rightPowerPhase != null) {
            rightPP = info.rightPowerPhase;
        }
        if (info has :rightPowerPhasePeak && info.rightPowerPhasePeak != null) {
            rightPPP = info.rightPowerPhasePeak;
        }
        if (info has :rightPlatformCenterOffset) {
            rightPCO = info.rightPlatformCenterOffset;
        }

        // Standing/sitting time (from cadence-based detection, available on some PMs)
        if (info has :timeStanding) { standingTime = info.timeStanding; }
        if (info has :timeSitting)  { seatedTime   = info.timeSitting; }

        // ─── accumulate time-in-zone for Power ───
        // simple 1-second accumulator: when this fires, the previous second's power
        // contributed to its zone. Uses current power as the latest sample.
        if (power != null && ftp > 0) {
            var z = Zones.powerZone(power, ftp);   // 1..7
            tizPower[z - 1] += 1;
        }
    }

    // ─── onUpdate() ───
    // Draws the entire screen. Called when the runtime decides to repaint.
    function onUpdate(dc) {
        _readSettings();

        var w = dc.getWidth();   // 282 on Edge 1030+
        var h = dc.getHeight();  // 470 on Edge 1030+

        // background
        dc.setColor(COL_BG, COL_BG);
        dc.clear();

        // ─── section heights ─── total = 470 px native
        // status 18 + prog 16 + power 130 + tiz 28 + hr 90 + tiles 65 + terrain 89 + footer 34 = 470
        var yStatus = 0;
        var yProg   = yStatus + 18;
        var yPower  = yProg + 16;
        var hPower  = 130;
        var yTiz    = yPower + hPower;
        var hTiz    = 28;
        var yHR     = yTiz + hTiz;
        var hHR     = 90;
        var yTiles  = yHR + hHR;
        var hTiles  = 65;
        var yPedal  = yTiles + hTiles;
        var hPedal  = 89;
        var yFooter = h - 34;

        _drawStatusBar(dc, yStatus, w);
        _drawSeparator(dc, yStatus + 18, w);

        _drawProgress(dc, yProg, w);
        _drawSeparator(dc, yProg + 16, w);

        _drawPowerSection(dc, yPower, hPower, w);
        _drawSeparator(dc, yPower + hPower, w);

        _drawTimeInZone(dc, yTiz, hTiz, w);
        _drawSeparator(dc, yTiz + hTiz, w);

        _drawHRSection(dc, yHR, hHR, w);
        _drawSeparator(dc, yHR + hHR, w);

        _drawTiles(dc, yTiles, hTiles, w);
        _drawSeparator(dc, yTiles + hTiles, w);

        _drawTerrain(dc, yPedal, hPedal, w);
        _drawSeparator(dc, yPedal + hPedal, w);

        _drawFooter(dc, yFooter, 34, w);
    }

    // ──────────────── status bar ────────────────
    function _drawStatusBar(dc, y, w) {
        var sysStats = System.getSystemStats();
        var battery  = sysStats.battery;     // float 0..100

        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(8, y + 9, Graphics.FONT_XTINY, timeStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // sensor status dots
        dc.setColor(COL_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(50, y + 9, 2);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(56, y + 9, Graphics.FONT_XTINY, "GPS",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COL_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(80, y + 9, 2);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(86, y + 9, Graphics.FONT_XTINY, "ANT",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // battery (right side)
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 26, y + 9, Graphics.FONT_XTINY, battery.format("%d") + "%",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        // battery icon
        dc.setColor(COL_GREEN, COL_BG);
        dc.fillRectangle(w - 22, y + 6, 18, 6);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(w - 22, y + 6, 18, 6);
    }

    // ──────────────── progress bar ────────────────
    function _drawProgress(dc, y, w) {
        var distKm = (distance != null) ? distance / 1000.0 : 0.0;
        var totalKm = null;
        var pct = 0.0;

        if (distanceToDest != null && distance != null) {
            // Course loaded — real progress
            var totalM = distance.toFloat() + distanceToDest.toFloat();
            if (totalM > 0) {
                totalKm = totalM / 1000.0;
                pct = distance.toFloat() / totalM;
            }
        }

        // distance text on left
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        var distLabel = (totalKm != null)
            ? distKm.format("%.1f") + " / " + totalKm.format("%.0f") + " km"
            : distKm.format("%.1f") + " km";
        dc.drawText(8, y + 8, Graphics.FONT_XTINY, distLabel,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // bar — only drawn if we have a course; otherwise the row stays clean
        var bx = 100, by = y + 6, bw = w - 160, bh = 4;
        if (totalKm != null) {
            if (pct > 1) { pct = 1.0; } else if (pct < 0) { pct = 0.0; }
            dc.setColor(0x222226, COL_BG);
            dc.fillRectangle(bx, by, bw, bh);
            dc.setColor(COL_GOLD, COL_BG);
            dc.fillRectangle(bx, by, (bw * pct).toNumber(), bh);
        }

        // ETA on right
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 8, y + 8, Graphics.FONT_XTINY, "ETA " + _etaStr(),
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Current clock time + remaining time on course → "16:08"
    function _etaStr() {
        if (timeToDest == null) { return "--:--"; }
        var now = System.getClockTime();
        var nowSec = (now.hour * 3600) + (now.min * 60) + now.sec;
        var etaSec = (nowSec + timeToDest.toNumber()) % 86400;
        var eh = etaSec / 3600;
        var em = (etaSec % 3600) / 60;
        return Lang.format("$1$:$2$", [eh, em.format("%02d")]);
    }

    // ──────────────── POWER section ────────────────
    function _drawPowerSection(dc, y, h, w) {
        var pad = 10;

        // section label
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 8, Graphics.FONT_XTINY, "POWER",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // big number on left
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 38, Graphics.FONT_NUMBER_MEDIUM, Format.int(power),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad + 78, y + 50, Graphics.FONT_XTINY, "W",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ø / ▲ line (avg/max)
        dc.setColor(COL_AVG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 64, Graphics.FONT_XTINY, "ø " + Format.int(avgPower),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad + 56, y + 64, Graphics.FONT_XTINY, "▲ " + Format.int(maxPower),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // sub-metrics on right
        var subX = w - pad;
        var ifVal  = (avgPower != null && ftp > 0) ? avgPower.toFloat() / ftp : null;
        var pctFTP = (power != null && ftp > 0) ? (power.toFloat() / ftp * 100).toNumber() : null;
        var wkg    = (power != null && weight > 0) ? power.toFloat() / weight : null;
        // L/R balance display reserved for when FIT-level balance is wired in
        _drawSubRight(dc, subX, y + 32, "IF",    Format.fixed(ifVal, 2));
        _drawSubRight(dc, subX, y + 47, "W/kg",  Format.fixed(wkg, 1));
        _drawSubRight(dc, subX, y + 62, "%FTP",  Format.int(pctFTP));

        // ─── zone bar ───
        var bx = pad, bw = w - 2 * pad, by = y + 80, bh = 14;
        var labels = ["Z1","Z2","Z3","Z4","Z5","Z6","Z7"];
        var curZone = Zones.powerZone(power, ftp);
        var curPos  = Zones.powerBarPos(power, ftp);
        var avgPos  = Zones.powerBarPos(avgPower, ftp);
        var maxPos  = Zones.powerBarPos(maxPower, ftp);
        ZoneBar.draw(dc, [bx, by, bw, bh],
                     Zones.POWER_COLORS, labels, curZone,
                     curPos, avgPos, maxPos);
    }

    function _drawSubRight(dc, rightX, y, label, value) {
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, y, Graphics.FONT_XTINY, value,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX - 30, y, Graphics.FONT_XTINY, label,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ──────────────── TIME IN ZONE bar ────────────────
    function _drawTimeInZone(dc, y, h, w) {
        var pad = 10;
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 7, Graphics.FONT_XTINY, "TIME IN ZONE",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // total
        var total = 0;
        for (var i = 0; i < tizPower.size(); i++) { total += tizPower[i]; }
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - pad, y + 7, Graphics.FONT_XTINY,
                    Format.duration(total) + " total",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // stacked bar
        if (total <= 0) { return; }
        var bx = pad, bw = w - 2 * pad, by = y + 16, bh = 10;
        var x = bx;
        for (var i = 0; i < tizPower.size(); i++) {
            var seg = ((tizPower[i].toFloat() / total) * bw).toNumber();
            if (seg <= 0) { continue; }
            dc.setColor(Zones.POWER_COLORS[i], Zones.POWER_COLORS[i]);
            dc.fillRectangle(x, by, seg, bh);
            x += seg;
        }
    }

    // ──────────────── HEART RATE section ────────────────
    function _drawHRSection(dc, y, h, w) {
        var pad = 10;

        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 8, Graphics.FONT_XTINY, "HEART RATE",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // big number
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 32, Graphics.FONT_NUMBER_MILD, Format.int(hr),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad + 60, y + 42, Graphics.FONT_XTINY, "BPM",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ø / ▲
        dc.setColor(COL_AVG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 54, Graphics.FONT_XTINY, "ø " + Format.int(avgHR),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad + 50, y + 54, Graphics.FONT_XTINY, "▲ " + Format.int(maxHR_v),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // sub-metrics
        var subX = w - pad;
        var pctLthr = (hr != null && lthr > 0) ? (hr.toFloat() / lthr * 100).toNumber() : null;
        var driftPct = DriftTracker.drift();
        var driftStr = "--";
        if (driftPct != null) {
            var sign = (driftPct >= 0) ? "+" : "";
            driftStr = sign + driftPct.format("%.1f") + "%";
        }
        _drawSubRight(dc, subX, y + 30, "%LTHR", Format.int(pctLthr));
        _drawSubRight(dc, subX, y + 45, "DRIFT", driftStr);

        // zone bar
        var bx = pad, bw = w - 2 * pad, by = y + 64, bh = 12;
        var curZone = Zones.hrZone(hr, maxHR);
        var curPos  = Zones.hrBarPos(hr, maxHR);
        var avgPos  = Zones.hrBarPos(avgHR, maxHR);
        var maxPos  = Zones.hrBarPos(maxHR_v, maxHR);
        var hrLabels = ["Z1","Z2","Z3","Z4","Z5"];
        ZoneBar.draw(dc, [bx, by, bw, bh],
                     Zones.HR_COLORS, hrLabels, curZone,
                     curPos, avgPos, maxPos);
    }

    // ──────────────── SPEED + CADENCE tiles ────────────────
    function _drawTiles(dc, y, h, w) {
        var halfW = w / 2;

        // vertical divider
        dc.setColor(COL_LINE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(halfW, y, halfW, y + h);

        var spdKmh = (speed != null) ? speed * 3.6 : null;
        var avgSpdKmh = (avgSpeed != null) ? avgSpeed * 3.6 : null;
        var maxSpdKmh = (maxSpeed != null) ? maxSpeed * 3.6 : null;

        _drawTile(dc, 0, y, halfW, h, "SPEED", "km/h",
                  Format.fixed(spdKmh, 1),
                  "ø " + Format.fixed(avgSpdKmh, 1) + "    ▲ " + Format.fixed(maxSpdKmh, 1));
        _drawTile(dc, halfW, y, halfW, h, "CADENCE", "rpm",
                  Format.int(cadence),
                  "ø " + Format.int(avgCadence) + "    ▲ " + Format.int(maxCadence));
    }

    // 9-arg max per Monkey C function — avg/max packed into a single caption string.
    function _drawTile(dc, x, y, w, h, label, unit, val, ammin) {
        var pad = 10;
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + pad, y + 8, Graphics.FONT_XTINY, label,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + pad, y + 30, Graphics.FONT_NUMBER_MILD, val,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + pad + 56, y + 38, Graphics.FONT_XTINY, unit,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + pad, y + h - 10, Graphics.FONT_XTINY, ammin,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ──────────────── TERRAIN ────────────────
    // Live grade (from TerrainTracker), current altitude, VAM, plus ride totals.
    // Optional NEXT row when course waypoints are loaded.
    function _drawTerrain(dc, y, h, w) {
        var pad = 10;

        // Section label
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, y + 8, Graphics.FONT_XTINY, "TERRAIN",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Totals (ascent / descent) — small, top-right.
        // Using +/- prefixes since FONT_XTINY doesn't render the unicode arrows.
        var ascStr  = (totalAscent  != null) ? "+" + totalAscent.toNumber().toString()  + "m" : "+--m";
        var dscStr  = (totalDescent != null) ? "-" + totalDescent.toNumber().toString() + "m" : "-0m";
        dc.setColor(COL_CAL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - pad, y + 8, Graphics.FONT_XTINY, ascStr,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        // descent left of ascent, with a gap
        var ascWidth = dc.getTextWidthInPixels(ascStr, Graphics.FONT_XTINY);
        dc.setColor(0x60a5fa, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - pad - ascWidth - 8, y + 8, Graphics.FONT_XTINY, dscStr,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Three primary cells: GRADE, ALTITUDE, VAM ──
        var grade = TerrainTracker.grade();
        var vam   = TerrainTracker.vam();
        var cellW = (w - 2 * pad) / 3;
        var cellY = y + 30;   // value baseline
        var lblY  = y + 50;   // label baseline

        // Grade
        var gradeStr = (grade != null) ? grade.format("%.1f") : "--";
        var gradeColor = COL_CAL;
        if (grade != null && grade < -0.5) { gradeColor = 0x60a5fa; }
        else if (grade != null && grade < 0.5) { gradeColor = COL_DIM; }
        dc.setColor(gradeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, cellY, Graphics.FONT_NUMBER_MILD, gradeStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad + 36, cellY + 8, Graphics.FONT_XTINY, "%",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pad, lblY, Graphics.FONT_XTINY, "GRADE",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Altitude
        var altStr = (altitude != null) ? altitude.toNumber().toString() : "--";
        var ax = pad + cellW;
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ax, cellY, Graphics.FONT_NUMBER_MILD, altStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ax + 38, cellY + 8, Graphics.FONT_XTINY, "m",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ax, lblY, Graphics.FONT_XTINY, "ALTITUDE",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // VAM
        var vamStr = (vam != null && vam > 0) ? vam.toString() : "--";
        var vx = pad + cellW * 2;
        dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx, cellY, Graphics.FONT_NUMBER_MILD, vamStr,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx + 40, cellY + 8, Graphics.FONT_XTINY, "m/h",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COL_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx, lblY, Graphics.FONT_XTINY, "VAM",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Next waypoint preview (only when on a course AND there's a real next point) ──
        // Skip if distance is trivial (no course loaded → field is often 0)
        // or elevation reading is bogus (== 0 typically means no course data)
        if (distanceToNextPoint != null && distanceToNextPoint > 100
            && elevationAtNextPoint != null && elevationAtNextPoint > 0
            && altitude != null) {
            var ny = y + 70;
            // dashed divider
            dc.setColor(COL_LINE, Graphics.COLOR_TRANSPARENT);
            for (var dx = pad; dx < w - pad; dx += 4) {
                dc.drawLine(dx, ny - 4, dx + 2, ny - 4);
            }

            dc.setColor(COL_CAL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(pad, ny + 6, Graphics.FONT_XTINY, "NEXT",
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var dKm = distanceToNextPoint.toFloat() / 1000.0;
            var dAlt = elevationAtNextPoint - altitude;
            var avgPct = (distanceToNextPoint > 5) ? (dAlt / distanceToNextPoint * 100) : 0;
            var sign = (dAlt >= 0) ? "+" : "";

            dc.setColor(COL_TEXT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(pad + 36, ny + 6, Graphics.FONT_XTINY,
                        "in " + dKm.format("%.1f") + " km  ·  " +
                        sign + dAlt.toNumber().toString() + " m  ·  " +
                        avgPct.format("%.1f") + "%",
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // ──────────────── FOOTER ────────────────
    function _drawFooter(dc, y, h, w) {
        var cellW = w / 4;
        var labels = ["RIDE", "TSS", "KCAL", "kJ"];
        var rideStr = Format.duration(elapsedTime);
        var tssStr  = _tssStr();
        var calStr  = Format.int(calories);
        // kJ of mechanical work done: avgPower (W) × time (s) / 1000 = kJ
        var kjStr = "--";
        if (avgPower != null && elapsedTime != null && elapsedTime > 0) {
            var kj = (avgPower.toFloat() * elapsedTime) / 1000.0;
            kjStr = kj.toNumber().toString();
        }
        var values = [rideStr, tssStr, calStr, kjStr];
        var colors = [COL_TEXT, COL_TEXT, COL_CAL, COL_TEXT];

        for (var i = 0; i < 4; i++) {
            var cx = i * cellW + cellW / 2;
            dc.setColor(COL_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + 8, Graphics.FONT_XTINY, labels[i],
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + 22, Graphics.FONT_TINY, values[i],
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // cell divider
            if (i < 3) {
                dc.setColor(COL_LINE, Graphics.COLOR_TRANSPARENT);
                dc.drawLine((i + 1) * cellW, y + 4, (i + 1) * cellW, y + h - 4);
            }
        }
    }

    function _tssStr() {
        // TSS = (sec × NP × IF) / (FTP × 3600) × 100
        // We don't have NP yet — approximate with avg power for now
        if (avgPower == null || elapsedTime == null || ftp <= 0) { return "--"; }
        var ifVal = avgPower.toFloat() / ftp;
        var tss = (elapsedTime * avgPower * ifVal) / (ftp * 3600.0) * 100.0;
        return tss.toNumber().toString();
    }

    // ──────────────── separators ────────────────
    function _drawSeparator(dc, y, w) {
        dc.setColor(COL_LINE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, y, w, y);
    }
}
