using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as WatchUi;

class BleScanner extends Ble.BleDelegate {
    var _model;
    var _pairing = false;
    var _testo = null;

    var _uuidFff0;
    var _uuidFff1;
    var _uuidFff2;
    var _uuid5a90;

    function initialize(model) {
        BleDelegate.initialize();

        _model = model;

        _uuidFff0 = Ble.stringToUuid(
            "0000fff0-0000-1000-8000-00805f9b34fb"
        );

        _uuidFff1 = Ble.stringToUuid(
            "0000fff1-0000-1000-8000-00805f9b34fb"
        );

        _uuidFff2 = Ble.stringToUuid(
            "0000fff2-0000-1000-8000-00805f9b34fb"
        );

        _uuid5a90 = Ble.stringToUuid(
            "00005a90-0000-1000-8000-00805f9b34fb"
        );

        registerTestoProfile();
    }

    function zeroPressure() {
        if (_testo != null) {
            _testo.zeroPressure();
        }
    }

    function registerTestoProfile() {
        var profile = {
            :uuid => _uuidFff0,
            :characteristics => [
                {
                    :uuid => _uuidFff1
                },
                {
                    :uuid => _uuidFff2,
                    :descriptors => [
                        Ble.cccdUuid()
                    ]
                }
            ]
        };

        Ble.registerProfile(profile);
    }

    function start() {
        _pairing = false;
        _testo = null;

        _model.pushStatus("Scanning...");
        _model.connected = false;
        _model.deviceName = null;
        _model.rssi = null;
        _model.raw = null;
        _model.serviceUuid = null;
        _model.pressurePsi = null;
        _model.saturationF = null;
        _model.dewF = null;
        _model.bubbleF = null;

        Ble.setDelegate(self);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);

        WatchUi.requestUpdate();
    }

    function stop() {
        Ble.setScanState(Ble.SCAN_STATE_OFF);
    }

    function onProfileRegister(uuid, status) {
        if (status != Ble.STATUS_SUCCESS) {
            _model.pushStatus("Profile err " + status);
            WatchUi.requestUpdate();
        }
    }

    function onScanStateChange(scanState, status) {
        if (status == Ble.STATUS_SUCCESS) {
            if (scanState == Ble.SCAN_STATE_SCANNING) {
                _model.pushStatus("Scan ON");
            } else if (!_pairing) {
                _model.pushStatus("Scan OFF");
            }
        } else {
            _model.pushStatus("Scan err " + status);
        }

        WatchUi.requestUpdate();
    }

    function onScanResults(scanResults) {
        var item = scanResults.next();

        while (item != null) {
            if (item instanceof Ble.ScanResult) {
                inspectResult(item);
            }

            item = scanResults.next();
        }

        WatchUi.requestUpdate();
    }

    function inspectResult(result) {
        if (_pairing) {
            return;
        }

        if (!isTestoAdvertisement(result)) {
            return;
        }

        _pairing = true;

        _model.pushStatus("Testo found");
        _model.rssi = result.getRssi();
        _model.serviceUuid = null;
        _model.raw = null;
        _model.deviceName = null;

        Ble.setScanState(Ble.SCAN_STATE_OFF);

        _model.pushStatus("Connecting...");
        WatchUi.requestUpdate();

        var device = Ble.pairDevice(result);

        if (device == null) {
            _pairing = false;
            _model.pushStatus("Pair failed");
            WatchUi.requestUpdate();
        }
    }

    function isTestoAdvertisement(result) {
        var uuids = result.getServiceUuids();
        var item = uuids.next();

        while (item != null) {
            if (item.equals(_uuidFff0) || item.equals(_uuid5a90)) {
                return true;
            }

            item = uuids.next();
        }

        return false;
    }

    function onConnectedStateChanged(device, state) {
        if (state == Ble.CONNECTION_STATE_CONNECTED) {
            _model.connected = true;
            _model.pushStatus("Connected");
            WatchUi.requestUpdate();

            _testo = new TestoDevice(
                device,
                _model,
                _uuidFff0,
                _uuidFff1,
                _uuidFff2
            );

            _testo.start();
            return;
        }

        if (state == Ble.CONNECTION_STATE_DISCONNECTED) {
            _pairing = false;
            _testo = null;

            _model.connected = false;
            _model.pushStatus("Disconnected");
            _model.deviceName = null;
            _model.raw = null;
            _model.serviceUuid = null;
            _model.pressurePsi = null;
            _model.saturationF = null;
            _model.dewF = null;
            _model.bubbleF = null;

            WatchUi.requestUpdate();
        }
    }

    function onDescriptorWrite(descriptor, status) {
        if (_testo != null) {
            _testo.onDescriptorWrite(descriptor, status);
        }
    }

    function onCharacteristicWrite(characteristic, status) {
        if (_testo != null) {
            _testo.onCharacteristicWrite(characteristic, status);
        }
    }

    function onCharacteristicChanged(characteristic, value) {
        if (_testo != null) {
            _testo.onCharacteristicChanged(characteristic, value);
        }
    }
}