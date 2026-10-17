using Toybox.WatchUi as WatchUi;

// Delegate for the custom root-page spine.
// Up/down use Garmin's native View transitions, so the whole page slides.
class WhiskerLinkDelegate extends WatchUi.BehaviorDelegate {
    var _model;
    var _scanner;
    var _rootIndex;

    function initialize(model, scanner, rootIndex) {
        BehaviorDelegate.initialize();

        _model = model;
        _scanner = scanner;
        _rootIndex = rootIndex;
    }

    function onPreviousPage() {
        // UP: global settings are above Probe 1.
        if (_rootIndex > WL_ROOT_REFRIGERANT) {
            switchRoot(
                _rootIndex - 1,
                WatchUi.SLIDE_DOWN
            );
        }

        return true;
    }

    function onNextPage() {
        // DOWN: for now Probe 1 is the lowest root page.
        // Probe 2+ can extend this bound later.
        if (_rootIndex < WL_ROOT_PROBE_1) {
            switchRoot(
                _rootIndex + 1,
                WatchUi.SLIDE_UP
            );
        }

        return true;
    }

    function onSelect() {
        if (_rootIndex == WL_ROOT_REFRIGERANT) {
            openRefrigerantMenu();
            return true;
        }

        if (_rootIndex == WL_ROOT_PROBE_1) {
            openProbeMenu();
            return true;
        }

        return false;
    }

    function switchRoot(targetIndex, transition) {
        var view;

        if (targetIndex == WL_ROOT_REFRIGERANT) {
            view = new RefrigerantRootView(_model);
        } else {
            view = new WhiskerLinkView(_model);
        }

        WatchUi.switchToView(
            view,
            new WhiskerLinkDelegate(
                _model,
                _scanner,
                targetIndex
            ),
            transition
        );
    }

    function openRefrigerantMenu() {
        var menu = new WatchUi.Menu2({
            :title => "Refrigerant",
            :icon => Rez.Drawables.SnowflakeIcon
        });

        menu.addItem(new WatchUi.MenuItem(
            "R-404A",
            currentLabel(Refrigerants.R404A),
            :r404a,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "R-410A",
            currentLabel(Refrigerants.R410A),
            :r410a,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "R-22",
            currentLabel(Refrigerants.R22),
            :r22,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "R-134a",
            currentLabel(Refrigerants.R134A),
            :r134a,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "R-290",
            currentLabel(Refrigerants.R290),
            :r290,
            {}
        ));

        WatchUi.pushView(
            menu,
            new RefrigerantMenuDelegate(_model),
            WatchUi.SLIDE_UP
        );
    }

    function currentLabel(refrigerant) {
        if (_model.selectedRefrigerant != null
            && _model.selectedRefrigerant.equals(refrigerant)) {
            return "Current";
        }

        return null;
    }

    function openProbeMenu() {
        var menu = new WatchUi.Menu2({
            :title => "549i",
            :icon => Rez.Drawables.InformationIcon
        });

        menu.addItem(new WatchUi.MenuItem(
            "Zero",
            null,
            :zero,
            {
                :icon => Rez.Drawables.ZeroGaugeIcon
            }
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Block",
            "Not implemented",
            :block,
            {
                :icon => Rez.Drawables.NoIcon
            }
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Device Info",
            null,
            :deviceInfo,
            {
                :icon => Rez.Drawables.InformationIcon
            }
        ));

        WatchUi.pushView(
            menu,
            new ProbeMenuDelegate(_model, _scanner),
            WatchUi.SLIDE_UP
        );
    }
}


// Native refrigerant selector.
class RefrigerantMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _model;

    function initialize(model) {
        Menu2InputDelegate.initialize();
        _model = model;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :r404a) {
            _model.selectedRefrigerant = Refrigerants.R404A;
        } else if (id == :r410a) {
            _model.selectedRefrigerant = Refrigerants.R410A;
        } else if (id == :r22) {
            _model.selectedRefrigerant = Refrigerants.R22;
        } else if (id == :r134a) {
            _model.selectedRefrigerant = Refrigerants.R134A;
        } else if (id == :r290) {
            _model.selectedRefrigerant = Refrigerants.R290;
        } else {
            return;
        }

        recalculateSaturation();

        // Return to the Refrigerant root card.
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function recalculateSaturation() {
        _model.saturationF = null;
        _model.dewF = null;
        _model.bubbleF = null;

        if (_model.pressurePsi == null) {
            WatchUi.requestUpdate();
            return;
        }

        var sat = Refrigerants.lookup(
            _model.selectedRefrigerant,
            _model.pressurePsi
        );

        if (sat != null) {
            _model.saturationF = sat[:saturationF];
            _model.dewF = sat[:dewF];
            _model.bubbleF = sat[:bubbleF];
        }

        WatchUi.requestUpdate();
    }
}


// Native probe actions menu.
class ProbeMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _model;
    var _scanner;

    function initialize(model, scanner) {
        Menu2InputDelegate.initialize();

        _model = model;
        _scanner = scanner;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :zero) {
            _scanner.zeroPressure();

            // Return directly to the instrument face.
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }

        if (id == :block) {
            // Future feature.
            return;
        }

        if (id == :deviceInfo) {
            openDeviceInfo();
        }
    }

    function openDeviceInfo() {
        var menu = new WatchUi.Menu2({
            :title => "Device Info",
            :icon => Rez.Drawables.InformationIcon
        });

        var firmware = _model.serviceUuid;
        if (firmware == null) {
            firmware = "Firmware unknown";
        }

        var battery = _model.raw;
        if (battery == null) {
            battery = "Battery unknown";
        }

        var rssi = "RSSI unknown";
        if (_model.rssi != null) {
            rssi = "RSSI " + _model.rssi + " dBm";
        }

        menu.addItem(new WatchUi.MenuItem(
            firmware,
            null,
            :firmware,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            battery,
            null,
            :battery,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            rssi,
            null,
            :rssi,
            {}
        ));

        WatchUi.pushView(
            menu,
            new DeviceInfoMenuDelegate(),
            WatchUi.SLIDE_UP
        );
    }
}


class DeviceInfoMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        // Informational rows only.
    }
}