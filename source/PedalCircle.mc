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
    function pedalToGraphics(pedalDeg) {
        return (90 - pedalDeg + 360) % 360;
    }

    // Draw a single pedal circle. Args packed for the 9-arg limit:
    //   dc      — drawing context
    //   cx, cy  — circle center
    //   r       — outer radius
    //   color   — arc color (green for left, blue for right)
    //   ppArc   — [startDeg, endDeg] in pedal degrees, or null
    //   pppArc  — [startDeg, endDeg], or null
    //   balance — left/right balance percent (e.g. 47), or null
    function draw(dc, cx, cy, r, color, ppArc, pppArc, balance) {

        // Background ring
        dc.setColor(0x1c1c1f, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawCircle(cx, cy, r);

        // Power Phase arc
        if (ppArc != null && ppArc.size() >= 2 && ppArc[0] != null && ppArc[1] != null) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(5);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE,
                       pedalToGraphics(ppArc[0]), pedalToGraphics(ppArc[1]));
        }

        // Peak Power Phase arc (thicker)
        if (pppArc != null && pppArc.size() >= 2 && pppArc[0] != null && pppArc[1] != null) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(9);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE,
                       pedalToGraphics(pppArc[0]), pedalToGraphics(pppArc[1]));
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
