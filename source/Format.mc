using Toybox.Lang;
using Toybox.Math;

// ─── Tiny formatting helpers — keep them allocation-free in the hot path ───
module Format {

    // Seconds → "h:mm:ss" or "mm:ss"
    function duration(secs) {
        if (secs == null) { return "--:--"; }
        var s = secs.toNumber();
        var h = s / 3600;
        var m = (s % 3600) / 60;
        var sec = s % 60;
        if (h > 0) {
            return Lang.format("$1$:$2$:$3$", [h, m.format("%02d"), sec.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [m.format("%02d"), sec.format("%02d")]);
    }

    // Float → fixed-decimal string, "--" for null
    function fixed(value, decimals) {
        if (value == null) { return "--"; }
        return value.format("%." + decimals + "f");
    }

    // Integer → string, "--" for null
    function int(value) {
        if (value == null) { return "--"; }
        return value.toNumber().toString();
    }

    // Float / int as percent → "87%"
    function pct(value) {
        if (value == null) { return "--%"; }
        return value.toNumber().toString() + "%";
    }

    // Clamp 0..1 → percentage of bar width
    function clamp01(v) {
        if (v < 0) { return 0.0; }
        if (v > 1) { return 1.0; }
        return v;
    }

    // Time-of-day from a Time::Moment → "16:08"
    function timeOfDay(moment) {
        var info = Toybox.Time.Gregorian.info(moment, Toybox.Time.FORMAT_SHORT);
        return Lang.format("$1$:$2$", [info.hour, info.min.format("%02d")]);
    }
}
