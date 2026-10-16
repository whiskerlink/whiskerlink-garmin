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

        // Left edge for the whole instrument face.
        var x = 26;

        // Small identity line.
        dc.drawText(
            x,
            16,
            Graphics.FONT_TINY,
            "549i",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // During startup / reconnect, show status rather than stale values.
        if (_model.deviceName == null) {
            dc.drawText(
                x,
                56,
                Graphics.FONT_SMALL,
                _model.status,
                Graphics.TEXT_JUSTIFY_LEFT
            );
            return;
        }

        // Temporary hardcoded saturation temperature.
        dc.drawText(
            x,
            38,
            Graphics.FONT_MEDIUM,
            "67\u00B0F",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Main measurement. Number-only font gives us a MUCH larger readout.
        dc.drawText(
            x,
            72,
            Graphics.FONT_NUMBER_THAI_HOT,
            pressureText(),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Unit underneath.
        dc.drawText(
            x,
            133,
            Graphics.FONT_TINY,
            "psi",
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    function pressureText() {
        if (_model.deviceName == null) {
            return "--.-";
        }

        var text = _model.deviceName;

        // Current TestoDevice format:
        // "P 12.3 psi"
        if (text.length() > 6
            && text.substring(0, 2).equals("P ")) {
            return text.substring(2, text.length() - 4);
        }

        return text;
    }
}