using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as WatchUi;

class BleScanner extends Ble.BleDelegate {
    var _model;

    function initialize(model) {
        BleDelegate.initialize();
        _model = model;
    }

    function start() {
        _model.status = "Scanning...";
        _model.deviceName = null;
        _model.rssi = null;
        _model.raw = null;
        _model.serviceUuid = null;

        Ble.setDelegate(self);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);

        WatchUi.requestUpdate();
    }

    function stop() {
        Ble.setScanState(Ble.SCAN_STATE_OFF);
    }

    function onScanStateChange(scanState, status) {
        if (status == Ble.STATUS_SUCCESS) {
            if (scanState == Ble.SCAN_STATE_SCANNING) {
                _model.status = "Scan ON";
            } else {
                _model.status = "Scan OFF";
            }
        } else {
            _model.status = "Scan err " + status;
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
        var name = result.getDeviceName();
        var rssi = result.getRssi();

        // Named devices are useful for diagnostics.
        if (name != null) {
            _model.status = "Named BLE";
            _model.deviceName = name;
            _model.rssi = rssi;
            _model.raw = bytesToHex(result.getRawData());
            _model.serviceUuid = firstServiceUuid(result);
            return;
        }

        // For nameless devices, keep the strongest one seen.
        if (_model.rssi == null || rssi > _model.rssi) {
            _model.status = "Nameless BLE";
            _model.deviceName = null;
            _model.rssi = rssi;
            _model.raw = bytesToHex(result.getRawData());
            _model.serviceUuid = firstServiceUuid(result);
        }
    }

    function firstServiceUuid(result) {
        var uuids = result.getServiceUuids();
        var item = uuids.next();

        if (item != null) {
            return item.toString();
        }

        return null;
    }

    function bytesToHex(data) {
        if (data == null) {
            return "";
        }

        var s = "";
        var limit = data.size();

        if (limit > 12) {
            limit = 12;
        }

        for (var i = 0; i < limit; i += 1) {
            if (i > 0) {
                s += " ";
            }

            s += byteToHex(data[i]);
        }

        return s;
    }

    function byteToHex(value) {
        var digits = "0123456789ABCDEF";

        var hi = (value >> 4) & 0x0F;
        var lo = value & 0x0F;

        return digits.substring(hi, hi + 1)
             + digits.substring(lo, lo + 1);
    }
}