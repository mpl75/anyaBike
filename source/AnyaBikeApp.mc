using Toybox.Application as App;
using Toybox.Application.Storage;
using Toybox.Background;
using Toybox.System;

class AnyaBikeApp extends App.AppBase {
  function initialize() {
    AppBase.initialize();
    if (System has :ServiceDelegate) {
      Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    }
  }

  // onStart() is called on application start up
  function onStart(state) {}

  // onStop() is called when your application is exiting
  function onStop(state) {
    Background.deleteTemporalEvent();
  }

  //! Return the initial view of your application here
  function getInitialView() {
    return [new AnyaBikeView()];
  }

  function getServiceDelegate() {
    return [new TemperatureServiceDelegate()];
  }

  function onBackgroundData(Temperature) {
    Storage.setValue("mytemp", Temperature);
  }
}
