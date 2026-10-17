using Toybox.Application as Application;

// Root-page positions.
// Global settings live at negative indexes, probes at 0 and below.
const WL_ROOT_REFRIGERANT = -1;
const WL_ROOT_PROBE_1 = 0;

class WhiskerLinkModel {
    var status;
    var statusHistory;
    var deviceName;
    var connected;
    var rssi;
    var raw;
    var serviceUuid;

    var pressurePsi;
    var saturationF;
    var dewF;
    var bubbleF;

    // Global app setting shared by all probes.
    var selectedRefrigerant;

    function initialize() {
        status = "Ready";
        statusHistory = ["Ready"];
        deviceName = null;
        connected = false;
        rssi = null;
        raw = null;
        serviceUuid = null;

        pressurePsi = null;
        saturationF = null;
        dewF = null;
        bubbleF = null;

        selectedRefrigerant = Refrigerants.R404A;
    }


    function pushStatus(text) {
        if (text == null) {
            return;
        }

        // Repeated live packets should not fill the history with the same
        // line over and over.
        if (status != null && status.equals(text)) {
            return;
        }

        status = text;

        // Array.remove() removes a matching VALUE in Monkey C, not an item
        // at an index. Rebuild the small scrollback buffer instead of trying
        // to shift it with remove(0).
        if (statusHistory.size() >= 12) {
            var trimmed = [];

            for (var i = statusHistory.size() - 11;
                 i < statusHistory.size();
                 i += 1) {
                trimmed.add(statusHistory[i]);
            }

            statusHistory = trimmed;
        }

        statusHistory.add(text);
    }

}

class WhiskerLinkApp extends Application.AppBase {
    var _model;
    var _scanner;

    function initialize() {
        AppBase.initialize();

        _model = new WhiskerLinkModel();
        _scanner = new BleScanner(_model);
    }

    function onStart(state) {
        _scanner.start();
    }

    function onStop(state) {
        _scanner.stop();
    }

    function getInitialView() {
        return [
            new WhiskerLinkView(_model),
            new WhiskerLinkDelegate(
                _model,
                _scanner,
                WL_ROOT_PROBE_1
            )
        ];
    }
}