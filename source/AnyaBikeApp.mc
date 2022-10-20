using Toybox.Application as App;
using Toybox.Background;
using Toybox.Time;
using Toybox.Application.Storage;

class AnyaBikeApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5*60));
            }
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new AnyaBikeView() ];
    }

    function onBackgroundData(Temperature) {
        Storage.setValue("mytemp", Temperature);
    }

}