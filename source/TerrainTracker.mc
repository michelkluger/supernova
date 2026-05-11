using Toybox.Lang;

// ─── TerrainTracker ───
// Connect IQ Activity.Info exposes altitude + totalAscent + totalDescent
// but NOT grade or VAM. We derive them from rolling samples.
//
// Grade  = Δaltitude / Δdistance   (over the last ~10 s window)
// VAM    = Δaltitude / Δtime × 3600  (positive only — climbing m/h)
module TerrainTracker {

    const WINDOW_SIZE = 10;          // 10 one-second samples ≈ 10 s smoothing

    var buf = null;                  // array of [altitude, distance, t] tuples
    var idx = 0;
    var filled = false;

    function reset() {
        buf = new[WINDOW_SIZE];
        for (var i = 0; i < WINDOW_SIZE; i++) { buf[i] = null; }
        idx = 0;
        filled = false;
    }

    // Call once per second from compute().
    function tick(altitude, distance, t) {
        if (buf == null) { reset(); }
        if (altitude == null || distance == null) { return; }

        buf[idx] = [altitude.toFloat(), distance.toFloat(), t];
        idx = (idx + 1) % WINDOW_SIZE;
        if (idx == 0) { filled = true; }
    }

    // Returns current grade as percent, or null if not enough data.
    function grade() {
        if (buf == null) { return null; }
        var oldest = _oldest();
        var newest = _newest();
        if (oldest == null || newest == null) { return null; }

        var dDist = newest[1] - oldest[1];
        var dAlt  = newest[0] - oldest[0];
        if (dDist < 5.0) { return 0.0; }   // need at least 5 m of motion to trust grade
        return (dAlt / dDist) * 100.0;
    }

    // Returns VAM in m/h. Positive when climbing, 0 when flat/descending.
    function vam() {
        if (buf == null) { return null; }
        var oldest = _oldest();
        var newest = _newest();
        if (oldest == null || newest == null) { return null; }

        var dAlt  = newest[0] - oldest[0];
        var dt    = newest[2] - oldest[2];
        if (dt < 1) { return 0; }
        if (dAlt <= 0) { return 0; }
        return ((dAlt / dt) * 3600.0).toNumber();
    }

    function _oldest() {
        // Oldest sample is at idx (next slot to overwrite), unless buffer not yet filled.
        if (!filled) {
            // First non-null sample
            for (var i = 0; i < WINDOW_SIZE; i++) {
                if (buf[i] != null) { return buf[i]; }
            }
            return null;
        }
        return buf[idx];
    }
    function _newest() {
        var i = (idx == 0) ? (WINDOW_SIZE - 1) : (idx - 1);
        return buf[i];
    }
}
