using Toybox.Graphics;

// ─── Garmin Connect zone palettes ───
// HR (5 zones):  gray, blue, green, orange, red
// Power (7 zones): gray, blue, green, yellow, orange, red, purple
module Zones {

    // ─── color constants — exported as 0xRRGGBB (Graphics expects this format) ───
    const HR_COLORS = [
        0x9CA3AF, 0x3B82F6, 0x22C55E, 0xF97316, 0xEF4444
    ];
    const POWER_COLORS = [
        0x9CA3AF, 0x3B82F6, 0x22C55E, 0xEAB308, 0xF97316, 0xEF4444, 0xA855F7
    ];

    // ─── Coggan-style power zone fractions of FTP (upper bound of each zone) ───
    // Z1 < 55%, Z2 55-75%, Z3 76-90%, Z4 91-105%, Z5 106-120%, Z6 121-150%, Z7 > 150%
    const POWER_BOUNDS = [ 0.55, 0.75, 0.90, 1.05, 1.20, 1.50 ];

    // Returns 1..7 given current power and FTP
    function powerZone(power, ftp) {
        if (power == null || ftp == null || ftp <= 0) { return 1; }
        var ratio = power.toFloat() / ftp.toFloat();
        for (var i = 0; i < POWER_BOUNDS.size(); i++) {
            if (ratio < POWER_BOUNDS[i]) { return i + 1; }
        }
        return 7;
    }

    // Returns 1..5 given HR and max HR (Garmin default %max bands)
    // Z1 < 60%, Z2 60-70%, Z3 70-80%, Z4 80-90%, Z5 > 90%
    function hrZone(hr, maxHR) {
        if (hr == null || maxHR == null || maxHR <= 0) { return 1; }
        var pct = hr.toFloat() / maxHR.toFloat();
        if (pct < 0.60) { return 1; }
        if (pct < 0.70) { return 2; }
        if (pct < 0.80) { return 3; }
        if (pct < 0.90) { return 4; }
        return 5;
    }

    // ─── Map a value to bar position (0..1) given the zone scale ───
    // For Power: scale 0 .. 1.5 × FTP
    // For HR: scale (maxHR × 0.5) .. maxHR
    function powerBarPos(value, ftp) {
        if (value == null || ftp == null) { return 0; }
        var pos = value.toFloat() / (ftp.toFloat() * 1.5);
        if (pos > 1) { pos = 1; }
        if (pos < 0) { pos = 0; }
        return pos;
    }
    function hrBarPos(value, maxHR) {
        if (value == null || maxHR == null) { return 0; }
        var lo = maxHR.toFloat() * 0.5;
        var pos = (value.toFloat() - lo) / (maxHR.toFloat() - lo);
        if (pos > 1) { pos = 1; }
        if (pos < 0) { pos = 0; }
        return pos;
    }
}
