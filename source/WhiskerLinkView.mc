using Toybox.Application as Application;
using Toybox.Graphics as Graphics;
using Toybox.WatchUi as WatchUi;


// Shared helper for custom root pages.
// For now every page uses LauncherIcon as a placeholder.
// Later, swap the resource here or split this into per-page resources.
module WhiskerLinkUi {
    function drawSubscreenIcon(dc, resourceId) {
        var subscreen = WatchUi.getSubscreen();

        if (subscreen == null) {
            return;
        }

        var icon = Application.loadResource(resourceId);

        var x = subscreen.x;
        var y = subscreen.y;

        if (x == null || y == null) {
            return;
        }

        // Center the bitmap inside the physical Instinct subscreen.
        x += (subscreen.width - icon.getWidth()) / 2;
        y += (subscreen.height - icon.getHeight()) / 2;

        dc.drawBitmap(x, y, icon);
    }
}


// The normal probe instrument face.
class WhiskerLinkView extends WatchUi.View {
    var _model;

    function initialize(model) {
        View.initialize();
        _model = model;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Instinct subscreen reflects actual BLE connection state.
        WhiskerLinkUi.drawSubscreenIcon(
            dc,
            _model.connected
                ? Rez.Drawables.GaugeIcon
                : Rez.Drawables.LauncherIcon
        );

        // Keep everything in the upper half biased left so it never
        // collides with the Instinct subscreen.
        var x = 20;

        dc.drawText(
            x,
            16,
            Graphics.FONT_TINY,
            "549i",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        if (_model.pressurePsi == null) {
            drawStatusHistory(dc, x);
            return;
        }

        drawSaturation(dc, x);

        // Pressure lives below the subscreen, so it can use the width.
        dc.drawText(
            x,
            82,
            Graphics.FONT_NUMBER_THAI_HOT,
            _model.pressurePsi.format("%.1f"),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.drawText(
            dc.getWidth() - 22,
            112,
            Graphics.FONT_TINY,
            "psi",
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    function drawStatusHistory(dc, x) {
        if (_model.statusHistory == null
            || _model.statusHistory.size() == 0) {
            return;
        }

        // Newest line hugs the bottom. Older lines climb upward like
        // terminal scrollback until they leave the display.
        var y = dc.getHeight() - 39;
        var lineHeight = 18;

        for (var i = _model.statusHistory.size() - 1;
             i >= 0 && y >= 0;
             i -= 1) {
            dc.drawText(
                x,
                y,
                Graphics.FONT_TINY,
                _model.statusHistory[i],
                Graphics.TEXT_JUSTIFY_LEFT
            );

            y -= lineHeight;
        }
    }


    function drawSaturation(dc, x) {
        if (_model.dewF != null && _model.bubbleF != null) {
            dc.drawText(
                x,
                38,
                Graphics.FONT_MEDIUM,
                _model.dewF.format("%.0f") + "\u00B0F D",
                Graphics.TEXT_JUSTIFY_LEFT
            );

            dc.drawText(
                x,
                59,
                Graphics.FONT_MEDIUM,
                _model.bubbleF.format("%.0f") + "\u00B0F B",
                Graphics.TEXT_JUSTIFY_LEFT
            );

            return;
        }

        if (_model.saturationF != null) {
            dc.drawText(
                x,
                38,
                Graphics.FONT_MEDIUM,
                _model.saturationF.format("%.0f") + "\u00B0F",
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }
    }
}


// Full-screen root card for the Refrigerant global setting.
// The title/value deliberately live at the bottom, below the subscreen.
class RefrigerantRootView extends WatchUi.View {
    var _model;

    function initialize(model) {
        View.initialize();
        _model = model;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        WhiskerLinkUi.drawSubscreenIcon(
            dc,
            Rez.Drawables.SnowflakeIcon
        );

        var center = dc.getWidth() / 2;

        dc.drawText(
            center,
            103,
            Graphics.FONT_SMALL,
            "Refrigerant",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            center,
            128,
            Graphics.FONT_LARGE,
            Refrigerants.displayName(_model.selectedRefrigerant),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}