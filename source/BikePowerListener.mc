using Toybox.AntPlus;

// ─── BikePowerListener ───
// Subscribes to the ANT+ Bike Power profile to get live Cycling-Dynamics data
// that Activity.Info does NOT expose on Edge 1030+:
//   • L/R balance        — pedal power balance, % per leg
//   • Torque effectiveness L/R
//   • Pedal smoothness L/R
//
// Power Phase / Peak Power Phase / PCO are not exposed via this API either —
// no public CIQ surface gives them on Edge.
class SupernovaPowerListener extends AntPlus.BikePowerListener {

    var leftBalance;          // % power from left leg (0..100), null until first sample
    var torqueEffL;            // % effectiveness left
    var torqueEffR;            // % effectiveness right
    var pedalSmoothL;          // % smoothness left
    var pedalSmoothR;          // % smoothness right

    function initialize() {
        BikePowerListener.initialize();
    }

    function onCalculatedPower(data) {
        // (we already get power from Activity.Info — ignore here)
    }

    function onPedalPowerBalance(data) {
        // data has fields: .pedalPowerPercent and .rightPedalIndicator
        // pedalPowerPercent = the share for whichever pedal is "the master"; the indicator
        // tells which one. Convention: store leftBalance as left's percentage.
        if (data != null && data.pedalPowerPercent != null) {
            if (data.rightPedalIndicator != null && data.rightPedalIndicator == true) {
                // pedalPowerPercent is the RIGHT share
                leftBalance = 100 - data.pedalPowerPercent;
            } else {
                leftBalance = data.pedalPowerPercent;
            }
        }
    }

    function onTorqueEffectivenessPedalSmoothness(data) {
        if (data == null) { return; }
        if (data has :leftTorqueEffectiveness)  { torqueEffL   = data.leftTorqueEffectiveness; }
        if (data has :rightTorqueEffectiveness) { torqueEffR   = data.rightTorqueEffectiveness; }
        if (data has :leftPedalSmoothness)      { pedalSmoothL = data.leftPedalSmoothness; }
        if (data has :rightPedalSmoothness)     { pedalSmoothR = data.rightPedalSmoothness; }
    }
}
