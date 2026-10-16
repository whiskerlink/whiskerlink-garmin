using Toybox.Application as Application;

class WhiskerLinkModel {
    var status;
    var deviceName;
    var rssi;
    var raw;
    var serviceUuid;

    function initialize() {
        status = "Ready";
        deviceName = null;
        rssi = null;
        raw = null;
        serviceUuid = null;
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
        return [ new WhiskerLinkView(_model) ];
    }
}