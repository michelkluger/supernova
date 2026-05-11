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

    // Draw a zone bar.
    //   dc        — drawing context
    //   x, y      — top-left of bar
    //   w, h      — bar dimensions
    //   colors    — array of zone colors (5 or 7 entries)
    //   labels    — array of zone labels parallel to colors (e.g. "Z1".."Z7"); pass null for no labels
    //   currentZone — 1..N, segment to highlight as bold
    //   curPos    — float 0..1, position of current marker on the full bar
    //   avgPos    — float 0..1, position of avg marker (or null)
    //   maxPos    — float 0..1, position of max marker (or null)
    //   avgLbl    — text shown ABOVE the avg marker, e.g. "ø198"
    //   maxLbl    — text shown BELOW the max marker, e.g. "▲612"
    function draw(dc, x, y, w, h, colors, labels, currentZone, curPos, avgPos, maxPos, avgLbl, maxLbl) {
        var n = colors.size();
        var segW = w.toFloat() / n;

        // ─── colored segments ───
        for (var i = 0; i < n; i++) {
            var sx = x + (i * segW).toNumber();
            var sw = ((i + 1) * segW).toNumber() - (i * segW).toNumber();
            dc.setColor(colors[i], colors[i]);
            dc.fillRectangle(sx, y, sw, h);

            // Darken non-current segments
            if (currentZone != null && (i + 1) != currentZone) {
                dc.setColor(0x000000, 0x000000);
                dc.setPenWidth(1);
                // use a translucent darken — Connect IQ has no alpha rect, so we do a 1px pattern
                _darkenRect(dc, sx, y, sw, h);
            }

            // segment label inside (e.g. Z1, Z2…)
            if (labels != null) {
                var isBold = (currentZone != null && (i + 1) == currentZone);
                dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
                var font = isBold ? Graphics.FONT_XTINY : Graphics.FONT_XTINY;
                dc.drawText(sx + (sw / 2), y + (h / 2), font, labels[i],
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // ─── current-position marker (white vertical line through bar) ───
        if (curPos != null) {
            var cx = x + (curPos * w).toNumber();
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx, y - MARKER_OVERHANG, MARKER_W, h + 2 * MARKER_OVERHANG);
        }

        // ─── AVG marker (red, label ABOVE) ───
        if (avgPos != null) {
            var ax = x + (avgPos * w).toNumber();
            dc.setColor(COLOR_AVG, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(ax, y - MARKER_OVERHANG, MARKER_W, h + 2 * MARKER_OVERHANG);
            if (avgLbl != null) {
                dc.drawText(ax + 1, y - MARKER_OVERHANG - LABEL_GAP, Graphics.FONT_XTINY, avgLbl,
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // ─── MAX marker (white, label BELOW) ───
        if (maxPos != null) {
            var mx = x + (maxPos * w).toNumber();
            dc.setColor(COLOR_MAX, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(mx, y - MARKER_OVERHANG, MARKER_W, h + 2 * MARKER_OVERHANG);
            if (maxLbl != null) {
                dc.drawText(mx + 1, y + h + MARKER_OVERHANG + LABEL_GAP, Graphics.FONT_XTINY, maxLbl,
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    // Stripe-darken a rect using 1px alternating lines — cheap alpha sim.
    hidden function _darkenRect(dc, x, y, w, h) {
        for (var dy = 0; dy < h; dy += 2) {
            dc.fillRectangle(x, y + dy, w, 1);
        }
    }
}
