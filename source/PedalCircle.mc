using Toybox.Graphics;
using Toybox.Math;

// ─── PedalCircle — power phase visualization ───
// Draws background ring + Power Phase arc (5px) + Peak Power Phase arc (10px, thicker)
// + TDC/BDC ticks + center balance %.
// Mirrors the Garmin Connect web visualization, dark-themed.
module PedalCircle {

    // Convert pedal angle (0=TDC, 90=3-o'clock, going clockwise) to Graphics arc start angle.
    // Graphics.drawArc uses: 0° = 3-o'clock, +90° = 12-o'clock (counter-clockwise math)
    // So pedal 0 (TDC) = graphics 90, pedal 90 (3 o'clock) = graphics 0, pedal 180 (BDC) = graphics 270 (or -90).
    hidden function pedalToGraphics(pedalDeg) {
        return (90 - pedalDeg + 360) % 360;
    }

    // Draw a single pedal circle.
    //   dc            — drawing context
    //   cx, cy        — circle center
    //   r             — outer radius
    //   color         — arc color (green for left, blue for right)
    //   ppStart, ppEnd  — Power Phase start/end in pedal degrees (0=TDC, clockwise)
    //   pppStart, pppEnd — Peak Power Phase angles
    //   balance       — left or right balance percentage (e.g. 47)
    function draw(dc, cx, cy, r, color, ppStart, ppEnd, pppStart, pppEnd, balance) {

        // Background ring
        dc.setColor(0x1c1c1f, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawCircle(cx, cy, r);

        // Power Phase arc (medium thickness)
        if (ppStart != null && ppEnd != null) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(5);
            // drawArc takes (cx, cy, r, attr, startDeg, endDeg)
            // attr: ARC_CLOCKWISE (1) or ARC_COUNTER_CLOCKWISE (0)
            // Graphics angles: 0=East, 90=North, 180=West, 270=South — ccw.
            // We want clockwise sweep from ppStart to ppEnd in PEDAL coords.
            var gStart = pedalToGraphics(ppStart);
            var gEnd   = pedalToGraphics(ppEnd);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, gStart, gEnd);
        }

        // Peak Power Phase arc (thicker)
        if (pppStart != null && pppEnd != null) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(9);
            var gpStart = pedalToGraphics(pppStart);
            var gpEnd   = pedalToGraphics(pppEnd);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, gpStart, gpEnd);
        }

        // TDC tick (top)
        dc.setColor(0x5a5a64, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(cx, cy - r - 4, cx, cy - r + 2);
        // BDC tick (bottom)
        dc.drawLine(cx, cy + r - 2, cx, cy + r + 4);

        // Center balance percentage
        if (balance != null) {
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_NUMBER_MILD,
                        balance.toNumber().toString() + "%",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
