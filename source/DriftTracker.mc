using Toybox.Lang;

// ─── DriftTracker ───
// Aerobic decoupling / cardiac drift. Compares Pw:Hr ratio across the ride:
//   baseline window = first ~10 minutes of pedaling
//   recent window   = rolling last 5 minutes
// Drift positive = HR has risen relative to power → fatigue / dehydration / Z2 ceiling.
// <5%  good aerobic durability for the intensity
// 5-10% growing fatigue
// >10% well past sustainable aerobic for the day
module DriftTracker {

    const BASELINE_SECONDS = 600;   // 10 min
    const RECENT_SECONDS   = 300;   // 5 min rolling

    var baselineSum = 0.0;
    var baselineCount = 0;
    var recent = null;              // circular buffer of last N samples (null = empty slot)
    var recentIdx = 0;
    var elapsed = 0;

    function reset() {
        baselineSum = 0.0;
        baselineCount = 0;
        recent = new[RECENT_SECONDS];
        for (var i = 0; i < RECENT_SECONDS; i++) { recent[i] = null; }
        recentIdx = 0;
        elapsed = 0;
    }

    // Call once per second from compute() with the latest power & HR.
    function tick(power, hr) {
        if (recent == null) { reset(); }
        elapsed += 1;
        if (power == null || hr == null || hr <= 0 || power <= 0) { return; }

        var pwHr = power.toFloat() / hr.toFloat();

        // Accumulate baseline for the first 10 min
        if (elapsed <= BASELINE_SECONDS) {
            baselineSum += pwHr;
            baselineCount += 1;
        }

        // Push to circular buffer (always — keeps a rolling window of the most recent samples)
        recent[recentIdx] = pwHr;
        recentIdx = (recentIdx + 1) % RECENT_SECONDS;
    }

    // Returns drift percent (positive = decoupling), or null if not enough baseline data yet.
    function drift() {
        if (recent == null) { return null; }
        // Require at least 5 min of baseline before drift is meaningful
        if (baselineCount < 300) { return null; }

        var baseline = baselineSum / baselineCount;
        if (baseline <= 0) { return null; }

        var rSum = 0.0;
        var rCount = 0;
        for (var i = 0; i < RECENT_SECONDS; i++) {
            var v = recent[i];
            if (v != null) {
                rSum += v;
                rCount += 1;
            }
        }
        if (rCount == 0) { return null; }
        var recentAvg = rSum / rCount;

        // When HR rises at same power, recent Pw:Hr drops below baseline → drift positive.
        return ((baseline - recentAvg) / baseline) * 100.0;
    }
}
