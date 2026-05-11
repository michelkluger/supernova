using Toybox.Application;
using Toybox.WatchUi;

class EdgeDataFieldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Start of activity — the runtime calls this before the first compute().
    function onStart(state) {}

    // End of activity — clean shutdown.
    function onStop(state) {}

    // Return the single full-screen DataField view.
    function getInitialView() {
        return [ new EdgeDataFieldView() ];
    }

    // Settings changed in the Connect IQ companion — re-read and refresh.
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}
