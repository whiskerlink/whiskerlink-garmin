using Toybox.Application as Application;

class GarminConnectTemplateApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new HelloWristView() ];
    }
}
