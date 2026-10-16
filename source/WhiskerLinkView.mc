using Toybox.Graphics as Graphics;
using Toybox.WatchUi as WatchUi;

class WhiskerLinkView extends WatchUi.View {
    var _model;

    function initialize(model) {
        View.initialize();
        _model = model;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;

        dc.drawText(
            cx,
            22,
            Graphics.FONT_SMALL,
            "WhiskerLink",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            cx,
            48,
            Graphics.FONT_TINY,
            _model.status,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (_model.deviceName != null) {
            dc.drawText(
                cx,
                68,
                Graphics.FONT_TINY,
                _model.deviceName,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else if (_model.rssi != null) {
            dc.drawText(
                cx,
                68,
                Graphics.FONT_TINY,
                "(nameless)",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        if (_model.rssi != null) {
            dc.drawText(
                cx,
                88,
                Graphics.FONT_TINY,
                "RSSI " + _model.rssi + " dBm",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        if (_model.serviceUuid != null) {
            dc.drawText(
                cx,
                108,
                Graphics.FONT_TINY,
                _model.serviceUuid,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        if (_model.raw != null) {
            dc.drawText(
                cx,
                132,
                Graphics.FONT_TINY,
                _model.raw,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }
}