using Toybox.Graphics;
using Toybox.WatchUi;

// ─── ZoneBar — the centerpiece visual ───
// Draws: colored zone segments, current-fill darken overlay, ø/▲ markers, labels.
// Reusable for Power (7 zones) and HR (5 zones).
module ZoneBar {

    // Layout constants for marker labels
    const MARKER_W = 2;
    const MARKER_OVERHANG = 3;        // marker tick extends this far above/below bar
    const LABEL_GAP = 4;              // gap between marker and label

    // Colors — keep in sync with the AVG/MAX convention used everywhere
    const COLOR_AVG = 0xEF4444;       // red
    const COLOR_MAX = 0xFFFFFF;       // white
    const COLOR_DIM = 0x000000;       // overlay color for unreached portion (50% alpha applied via dither)

    // Draw a zone bar. Args packed to stay under Monkey C's 9-arg limit:
    //   dc       — drawing context
    //   rect     — [x, y, w, h]
    //   colors   — array of zone colors (5 or 7)
    //   labels   — array of segment labels (Z1..Zn) or null
    //   curZone  — 1..n, segment to highlight; null = no highlight
    //   curPos   — 0..1, current marker position (null = no marker)
    //   avgPos   — 0..1, avg marker position (null = none)
    //   maxPos   — 0..1, max marker position (null = none)
    function draw(dc, rect, colors, labels, curZone, curPos, avgPos, maxPos) {
        var x = rect[0]; var y = rect[1]; var w = rect[2]; var h = rect[3];
        var n = colors.size();
        var segW = w.toFloat() / n;

        // ─── colored segments ───
        for (var i = 0; i < n; i++) {
            var sx = x + (i * segW).toNumber();
            var sw = ((i + 1) * segW).toNumber() - (i * segW).toNumber();
            dc.setColor(colors[i], colors[i]);
            dc.fillRectangle(sx, y, sw, h);

            // Darken non-current segments
            if (curZone != null && (i + 1) != curZone) {
                dc.setColor(0x000000, 0x000000);
                dc.setPenWidth(1);
                // use a translucent darken — Connect IQ has no alpha rect, so we do a 1px pattern
                _darkenRect(dc, sx, y, sw, h);
            }

            // segment label inside (e.g. Z1, Z2…)
            if (labels != null) {
                dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
                dc.drawText(sx + (sw / 2), y + (h / 2), Graphics.FONT_XTINY, labels[i],
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // ─── current-position marker (white vertical line through bar) ───
        if (curPos != null) {
            var cx = x + (curPos * w).toNumber();
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx, y - MARKER_OVERHANG, MARKER_W, h + 2 * MARKER_OVERHANG);
        }
        // ─── AVG marker (red) ───
        if (avgPos != null) {
            var ax = x + (avgPos * w).toNumber();
            dc.setColor(COLOR_AVG, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(ax, y - MARKER_OVERHANG, MARKER_W, h + 2 * MARKER_OVERHANG);
        }
        // ─── MAX marker (white) ───
        if (maxPos != null) {
            var mx = x + (maxPos * w).toNumber();
            dc.setColor(COLOR_MAX, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(mx, y - MARKER_OVERHANG, MARKER_W, h + 2 * MARKER_OVERHANG);
        }
    }

    // Stripe-darken a rect using 1px alternating lines — cheap alpha sim.
    function _darkenRect(dc, x, y, w, h) {
        for (var dy = 0; dy < h; dy += 2) {
            dc.fillRectangle(x, y + dy, w, 1);
        }
    }
}
