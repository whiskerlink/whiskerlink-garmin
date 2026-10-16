using Toybox.Application as Application;

class WhiskerLinkApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new WhiskerLinkView() ];
    }
}