using Toybox.WatchUi as WatchUi;

class WhiskerLinkDelegate extends WatchUi.BehaviorDelegate {
    var _scanner;

    function initialize(scanner) {
        BehaviorDelegate.initialize();
        _scanner = scanner;
    }

    function onSelect() {
        _scanner.zeroPressure();
        return true;
    }
}