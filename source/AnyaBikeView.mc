using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.SensorHistory;
using Toybox.Sensor;
using Toybox.Background;
using Toybox.Application.Storage;


class AnyaBikeView extends Ui.DataField {

	hidden var display;
  var GPSaccuracy, sunset, temperature, altitude, averageCadence, averageSpeed, currentHeading, currentHeartRate, currentCadence, currentSpeed, elapsedDistance, elapsedTime, maxCadence, maxSpeed, timerTime, totalAscent;
	var compass, elapsedDistanceText, clockTime;
	hidden var sumAlt, countAlt, lastTM, lastDoneTM;
	hidden var memoryAlt;
	var font, fontsport;
	var bgColor, txtColor, lineColor;
	var slope, slopeText, slopeIcon, slopeColor, slopeColorText;
	var spdUnitText, altUnitText, distUnitText, tempUnitText;
	
	var sc = new SunCalc();
	var zoneInfo;

    function initialize() {
        DataField.initialize();
        
        display = new Display();
        
        altitude = 0.0f;
        averageCadence = 0.0f;
        averageSpeed = 0.0f;
        currentCadence = 0;
        currentHeading = null;
        currentHeartRate = null;
        currentSpeed = 0.0f;
        elapsedDistance = 0.0f;        
        elapsedTime = 0.0f;
        maxCadence = 0.0f;
        maxSpeed = 0.0f;
        timerTime = 0.0f;
        totalAscent = 0.0f;
        temperature = 0;
        GPSaccuracy = 0;
        sunset = null;
        
        compass = 0;
        slope = 0;
        sumAlt = 0;
        countAlt = 0;
        lastTM = -1;
        lastDoneTM = null;
        memoryAlt = new [10];
        for (var i = 0; i < 10; i++) {
          memoryAlt[i] = null;
        }
        
        font = Ui.loadResource(Rez.Fonts.text);
        fontsport = Ui.loadResource(Rez.Fonts.sport);
        
        zoneInfo = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
    }
    
    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        return true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
      if(info has :altitude){
        if(info.altitude != null){
          altitude = info.altitude.toFloat();
        } else {
          altitude = 0.0f;
        }
      }
      if(info has :averageCadence){
        if(info.averageCadence != null){
          averageCadence = info.averageCadence;
        } else {
          averageCadence = 0.0f;
        }
      }
      if(info has :averageSpeed){
        if(info.averageSpeed != null){
          averageSpeed = info.averageSpeed * 3.6;
        } else {
          averageSpeed = 0.0f;
        }
      }
      if(info has :currentHeading){
        if(info.currentHeading != null){
          currentHeading = info.currentHeading * (180 / 3.1415926);
          if (currentHeading < 0) {
            currentHeading += 360;
          }
        } else {
          currentHeading = null;
        }
      }
      if(info has :currentHeartRate){
        if(info.currentHeartRate != null){
          currentHeartRate = info.currentHeartRate;
        } else {
          currentHeartRate = null;
        }
      }
      if(info has :currentLocationAccuracy){
        if(info.currentLocationAccuracy != null){
          GPSaccuracy = info.currentLocationAccuracy;
        } else {
          GPSaccuracy = 0;
        }
      }
      if(info has :currentCadence){
        if(info.currentCadence != null){
          currentCadence = info.currentCadence;
        } else {
          currentCadence = null;
        }
      }
      if(info has :currentSpeed){
        if(info.currentSpeed != null){
          currentSpeed = info.currentSpeed * 3.6;
        } else {
          currentSpeed = 0.0f;
        }
      }
      if(info has :elapsedDistance){
        if(info.elapsedDistance != null){
          elapsedDistance = info.elapsedDistance / 1000;          
        } else {
          elapsedDistance = 0.0f;
        }
      }
      if(info has :elapsedTime){
        if(info.elapsedTime != null){
          elapsedTime = info.elapsedTime / 1000;
        } else {
          elapsedTime = 0.0f;
        }
      }
      if(info has :maxCadence){
        if(info.maxCadence != null){
          maxCadence = info.maxCadence;
        } else {
          maxCadence = 0.0f;
        }
      }
      if(info has :maxSpeed){
        if(info.maxSpeed != null){
          maxSpeed = info.maxSpeed * 3.6;
        } else {
          maxSpeed = 0.0f;
        }
      }
      if(info has :timerTime){
        if(info.timerTime != null){
          timerTime = info.timerTime / 1000;
        } else {
          timerTime = 0.0f;
        }
      }
      if(info has :totalAscent){
        if(info.totalAscent != null){
          totalAscent = info.totalAscent.toFloat();
        } else {
          totalAscent = 0.0f;
        }
      }
      // var sinfo=Sensor.getInfo();
 
       if (Storage.getValue("mytemp") != null) {
               temperature = Storage.getValue("mytemp").toFloat();
       }  else{
          var tempIter = Toybox.SensorHistory.getTemperatureHistory({
            :period => 1
          });
          if (tempIter != null) {
            temperature = tempIter.next().data.toFloat();
          } else {
            temperature = null;
          }
      }  
     
            
      sumAlt += altitude;
      countAlt++;
      var fullTM = elapsedDistance * 100;
      var curTM = fullTM.toNumber() % 10;
      var curDoneTM = fullTM / 10;
      curDoneTM = curDoneTM.toNumber();
      if (lastDoneTM == null) {
        lastDoneTM = curDoneTM;
      }
      if (curTM > lastTM || curDoneTM > lastDoneTM) {
        var curAlt = sumAlt / countAlt;
        var prevAlt = memoryAlt[curTM];
        if (prevAlt != null) {
          slope = curAlt - prevAlt;
        }
        while (lastTM < curTM || lastDoneTM < curDoneTM) {
          lastTM++;
          if (lastTM >= 10) {
            lastTM = 0;
            lastDoneTM++;
          }
          memoryAlt[lastTM] = curAlt;
        }

        lastTM = curTM;
        lastDoneTM = curDoneTM;
        sumAlt = 0;
        countAlt = 0;
      }
      
      var now = Time.now();
      var loc = info.currentLocation;
      if (loc != null) {
        var sunset_moment = sc.calculate(now, loc.toRadians(), SUNSET);
        sunset = Gregorian.info(sunset_moment, Time.FORMAT_SHORT);
      } else {
        sunset = null;
      }
    }
    
    function textWithIconOnCenter(dc, text, icon, unit, x, y, fnt, hShift) {
      var w = dc.getTextWidthInPixels(text, fnt).toDouble() / 2;
      w = w.toNumber();
      dc.drawText(x - w - 2, y + hShift, fontsport, icon, Gfx.TEXT_JUSTIFY_RIGHT);
      dc.drawText(x, y, fnt, text, Gfx.TEXT_JUSTIFY_CENTER);
      dc.drawText(x + w + 1, y + hShift, font, unit, Gfx.TEXT_JUSTIFY_LEFT);
    }
    
    function formatTime(sec) {
      sec = sec.toLong();
      var h = (sec / 3600) % 24;
      var m = (sec / 60) % 60;
      var s = sec % 60;
      var text = "-:--";
      if (h > 0) {
        text = h.format("%d") + "." + m.format("%02d");
      } else {
        text = m.format("%d") + ":" + s.format("%02d");
      }
      return text;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Graphics.Dc) {
      /* currentSpeed += 2.13;
      if (currentSpeed > 65) {
        currentSpeed = 0;
        } 

      slope += 1.23;
      if (slope > 13) {
        slope = -13;
      }
      altitude = 384;
      totalAscent = 234; */

      var systemSettings = System.getDeviceSettings();
      if (systemSettings.paceUnits == System.UNIT_STATUTE) {
        spdUnitText = "mph";
        averageSpeed /= 1.609344;
        currentSpeed /= 1.609344;
        maxSpeed /= 1.609344;
      } else {
        spdUnitText = "km/h";
      }
      if (systemSettings.elevationUnits == System.UNIT_STATUTE) {
        altUnitText = "ft";
        altitude *= 3.2808399;
        totalAscent *= 3.2808399;
      } else {
        altUnitText = "m";
      }
      if (systemSettings.distanceUnits == System.UNIT_STATUTE) {
        distUnitText = "mi";
        elapsedDistance /= 1.609344;
      } else {
        distUnitText = "km";
      }
      if (systemSettings.temperatureUnits == System.UNIT_STATUTE) {
        tempUnitText = " °F";
        temperature = temperature * 9 / 5 + 32;
      } else {
        tempUnitText = " °C";
      }

      slopeText = "0";
      slopeIcon = " ";
      slopeColor = -1;
      slopeColorText = 0x000000;
      if (slope.abs() >= 10) {
            slopeText = slope.abs().format("%d");
      } else if (slope != 0) {
            slopeText = slope.abs().format("%.1f");
        } 
      if (slope <= -5) {
        slopeIcon = "V";
        slopeColor = 0x00AAFF;
      } else if (slope < 0) {
        slopeIcon = "T";
        if (slope <= -2) {
          slopeColor = 0x00FF00;
        }
      } else if (slope >= 5) {
        slopeIcon = "U";
        slopeColor = 0xFF0000;
            slopeColorText = 0xFFFFFF;
      } else if (slope > 0) {
        slopeIcon = "S";
        if (slope >= 2) {
          slopeColor = 0xFFAA00;
        }
      }
      
      if (elapsedDistance >= 100) {
        elapsedDistanceText = elapsedDistance.format("%.1f");
      } else {
        elapsedDistanceText = elapsedDistance.format("%.2f");
      }
      
      clockTime = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		
      bgColor = getBackgroundColor();
      txtColor = Gfx.COLOR_BLACK;
      lineColor = Gfx.COLOR_LT_GRAY;
      if (bgColor == Gfx.COLOR_BLACK) {
        txtColor = Gfx.COLOR_WHITE;
        lineColor = Gfx.COLOR_DK_GRAY;
      }
      dc.setColor(txtColor, -1);
      dc.clear();

/* ----- */        
		
		  dc.drawText(dc.getWidth()/2, dc.getHeight()/2-40, Gfx.FONT_NUMBER_THAI_HOT, currentSpeed.format("%d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
      dc.drawText(dc.getWidth()/2+36, dc.getHeight()/2-74, font, spdUnitText, Gfx.TEXT_JUSTIFY_LEFT);

      textWithIconOnCenter(dc, altitude.format("%d"), "G", altUnitText, 40, dc.getHeight()/2, Gfx.FONT_MEDIUM, 10);
      textWithIconOnCenter(dc, totalAscent.format("%d"), "H", altUnitText, dc.getWidth()-44, dc.getHeight()/2, Gfx.FONT_MEDIUM, 10);
        
      dc.setColor(slopeColor, -1);
      dc.fillRectangle(dc.getWidth()/2-30, dc.getHeight(), 60, 34);
      dc.setColor(slopeColorText, -1);
      textWithIconOnCenter(dc, slopeText, slopeIcon, "%", dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_MEDIUM, 10);

      dc.setColor(txtColor, -1);					
      textWithIconOnCenter(dc, elapsedDistanceText, "", distUnitText, dc.getWidth()/2, display.line2Y-8, Gfx.FONT_NUMBER_MEDIUM, 27);  


      var leftSegment = Application.Properties.getValue("leftSegment");
      if (currentHeartRate != null && leftSegment == 1) {
		    dc.setColor(txtColor, lineColor);
        if (currentHeartRate >= zoneInfo[4]) {
          dc.setColor(0xFFFFFF, 0xFF0000);
        } else if (currentHeartRate >= zoneInfo[3]) {
          dc.setColor(0x000000, 0xFFAA00);
        } else if (currentHeartRate >= zoneInfo[2]) {
          dc.setColor(0x000000, 0x00FF00);
        } else if (currentHeartRate >= zoneInfo[1]) {
          dc.setColor(0x000000, 0x00AAFF);
        } else {
          dc.setColor(txtColor, lineColor);
        }
        dc.drawText(24, display.line2Y, fontsport, "  I ", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(txtColor, -1);
        dc.drawText(26, display.line2Y -2, Gfx.FONT_MEDIUM, currentHeartRate.format("%d"), Gfx.TEXT_JUSTIFY_LEFT);
		  }
		
      var rightSegment = Application.Properties.getValue("rightSegment");
      if (currentCadence != null && rightSegment == 1) {
        var cadenceBlue = Application.Properties.getValue("cadenceBlue").toNumber();
        var cadenceGreen = Application.Properties.getValue("cadenceGreen").toNumber();
        var cadenceOrange = Application.Properties.getValue("cadenceOrange").toNumber();
        var cadenceRed = Application.Properties.getValue("cadenceRed").toNumber();
        if (currentCadence > cadenceRed) {
		      dc.setColor(0xFFFFFF, 0xFF0000);
        } else if (currentCadence > cadenceOrange) {
		      dc.setColor(0x000000, 0xFFAA00);
        } else if (currentCadence > cadenceGreen) {
          dc.setColor(0x000000, 0x00FF00);
        } else if (currentCadence > cadenceBlue) {
          dc.setColor(0x000000, 0x00AAFF);
        } else {
          dc.setColor(txtColor, lineColor);
        }
        dc.drawText(dc.getWidth()-24, display.line2Y, fontsport, " W  ", Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(txtColor, -1);
        dc.drawText(dc.getWidth()-26, display.line2Y -2, Gfx.FONT_MEDIUM, currentCadence.format("%d"), Gfx.TEXT_JUSTIFY_RIGHT);
		  }

      if (leftSegment == 2 || rightSegment == 2) {
        var timerTimeText = formatTime(timerTime);
        if (leftSegment == 2) {
          dc.drawText(16, display.line2Y -2, Gfx.FONT_SMALL, timerTimeText, Gfx.TEXT_JUSTIFY_LEFT);
        }
        if (rightSegment == 2) {
          dc.drawText(dc.getWidth()-16, display.line2Y -2, Gfx.FONT_SMALL, timerTimeText, Gfx.TEXT_JUSTIFY_RIGHT);
        }
      }
		
      if (leftSegment == 3 || rightSegment == 3) {
        var elapsedTimeText = formatTime(elapsedTime);
        if (leftSegment == 3) {
          dc.drawText(16, display.line2Y -2, Gfx.FONT_SMALL, elapsedTimeText, Gfx.TEXT_JUSTIFY_LEFT);
        }
        if (rightSegment == 3) {
          dc.drawText(dc.getWidth()-16, display.line2Y -2, Gfx.FONT_SMALL, elapsedTimeText, Gfx.TEXT_JUSTIFY_RIGHT);
        }
      }

		  dc.drawText(dc.getWidth()/2, 30, Gfx.FONT_SMALL, clockTime.hour + ":" + clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

      if (clockTime.sec % 6 < 3 && rightSegment == 1) {
        dc.drawText(50, dc.getHeight()/2-36, Gfx.FONT_MEDIUM, averageCadence.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(50, dc.getHeight()/2-52, fontsport, "X", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()-50, dc.getHeight()/2-36, Gfx.FONT_MEDIUM, maxCadence.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()-50, dc.getHeight()/2-52, fontsport, "Y", Gfx.TEXT_JUSTIFY_CENTER);
      } else {
        dc.drawText(50, dc.getHeight()/2-36, Gfx.FONT_MEDIUM, averageSpeed.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(50, dc.getHeight()/2-52, fontsport, "D", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()-50, dc.getHeight()/2-36, Gfx.FONT_MEDIUM, maxSpeed.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()-50, dc.getHeight()/2-52, fontsport, "E", Gfx.TEXT_JUSTIFY_CENTER);
      }
		
      if (temperature != null) {
        dc.setColor(0x00AAFF, -1);
        dc.drawText(74, display.line3Y+2, fontsport, "B", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(txtColor, -1);
        dc.drawText(76, display.line3Y+2, font, temperature.format("%d") + tempUnitText, Gfx.TEXT_JUSTIFY_LEFT);
      }
      var sunsetText = "-:--";
      if (sunset != null) {
        sunsetText = sunset.hour + ":" + sunset.min.format("%02d");
      }	
      // sunsetText = "19:38";
      dc.setColor(0xFFAA00, -1);
      dc.drawText(display.sunsetX, display.line3Y+2, fontsport, "A", Gfx.TEXT_JUSTIFY_RIGHT);
      dc.setColor(txtColor, -1);
      dc.drawText(display.sunsetX+2, display.line3Y+2, font, sunsetText, Gfx.TEXT_JUSTIFY_LEFT);

      if (currentHeading != null) {
        var headDiff = currentHeading - compass;
        if (headDiff > 180) {
          headDiff = headDiff - 360;
        }
        if (headDiff > 40) {
          headDiff = 40;
        } else if (headDiff < -40) {
          headDiff = -40;
        }
        compass += headDiff / 2;
        if (compass < 0) {
          compass += 360;
        }
        dc.drawText(display.compasOffset - compass, dc.getHeight()-18, fontsport, "RQRJRKRLRMRNRORPRQRJRKR", Gfx.TEXT_JUSTIFY_LEFT);
      }

      var gpsColor = txtColor;
      switch (GPSaccuracy) {
        case 0:
        case 1: gpsColor = 0xFF0000; break;
        case 2: gpsColor = 0xFF5500; break;
        case 3: gpsColor = 0xFFAA00; break;
        case 4: gpsColor = 0x00FF00; break;
      }
      for (var i = 0; i < 4; i++) {
        dc.setColor(GPSaccuracy > i ? gpsColor : lineColor, bgColor);
        dc.fillRectangle(74 + i * 3, 38 - i * 2, 2, i * 2 + 2);
      }
      
      dc.setColor(txtColor, -1);
      var batteryX = dc.getWidth()-89;
      dc.drawRoundedRectangle(batteryX, 32, 19, 9, 1);		
      dc.drawRectangle(batteryX+19, 35, 1, 3);		
      var systemStats = System.getSystemStats();
      var battery = systemStats.battery / 25 + 1;
      battery = battery.toNumber();
      if (battery > 4) {
        battery = 4;
      }
      for (var i = 0; i < battery; i++) {
        dc.setColor(systemStats.battery > 10 ? 0x00FF00 : 0xFF0000, bgColor);
        dc.fillRectangle(batteryX + 2 + i * 4, 34, 3, 5);
      }
      


      var speedGreen = Application.Properties.getValue("speedGreen").toNumber();
      var speedOrange = Application.Properties.getValue("speedOrange").toNumber();
      var speedRed = Application.Properties.getValue("speedRed").toNumber();
      var step = 15;
      var speed = currentSpeed / 60 * 180;
      speed = speed.toNumber();
      if (speed > 179) {
        speed = 179;
      }
      speed++;
      var speedColor = 0x00AAFF;
      if (currentSpeed > speedRed) {
        speedColor = 0xFF0000;
      } else if (currentSpeed > speedOrange) {
        speedColor = 0xFFAA00;
      } else if (currentSpeed > speedGreen) {
        speedColor = 0x00FF00;
      }
		
      dc.setPenWidth(10);
      dc.setColor(lineColor, -1);
	    dc.drawArc(display.centerX, display.centerY, display.halfr, Gfx.ARC_CLOCKWISE, 180, 0);
      dc.setColor(speedColor, -1);
	    dc.drawArc(display.centerX, display.centerY, display.halfr, Gfx.ARC_CLOCKWISE, 180, 180 - speed);
      dc.setPenWidth(20);
	    for (var i = 1; i < 12; i++) {
	      dc.setColor(speed > i * step ? speedColor : lineColor, bgColor);
	      dc.drawArc(display.centerX, display.centerY, display.halfr, Gfx.ARC_CLOCKWISE, 180 - i * step, 180 - i * step - 1);
      }

      dc.setColor(lineColor, bgColor);
      dc.setPenWidth(1);
      dc.drawLine(0, display.line1Y, display.width, display.line1Y);

      dc.drawLine(0, display.line2Y, display.width, display.line2Y);
      
      dc.drawLine(0, display.line3Y, display.width, display.line3Y);
    }

}

(:background)
class TemperatureServiceDelegate extends System.ServiceDelegate {
  function initialize() {
    ServiceDelegate.initialize();
  }

  function onTemporalEvent() {
    Sensor.setEnabledSensors([Sensor.SENSOR_TEMPERATURE]);
    Sensor.enableSensorEvents(method(:onSensor));
  }

  function onSensor(sensorInfo) {
    //var sensorInfo = Sensor.getInfo();
    var temperature;
    if (sensorInfo has :temperature && sensorInfo.temperature != null) {
      temperature = sensorInfo.temperature;
    } else {
      temperature = null;
    }
    Background.exit(temperature);
  }
}
