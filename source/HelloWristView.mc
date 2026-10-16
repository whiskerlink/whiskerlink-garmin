using Toybox.Graphics as Graphics;
using Toybox.WatchUi as WatchUi;

class HelloWristView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.drawText(
            cx,
            cy - 12,
            Graphics.FONT_MEDIUM,
            "Hello Wrist",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            cx,
            cy + 14,
            Graphics.FONT_TINY,
            "Instinct 2",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
