using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.SensorHistory;

(:typecheck(false))
class AnyaBikeView extends Ui.DataField {

	hidden var display;
  var GPSaccuracy, sunset, temperature, altitude, averageCadence, averageSpeed, currentHeading, currentHeartRate, currentCadence, currentSpeed, elapsedDistance, elapsedTime, maxCadence, maxSpeed, timerTime, totalAscent, curSpeed, currentPower;
	var compass, elapsedDistanceText, clockTime;
	hidden var sumAlt, countAlt, lastTM, lastDoneTM;
	hidden var memoryAlt;
	hidden var buffer, bufferSize, bufferPos, previousAltitude;
	var font, fontsport;
	var bgColor, txtColor, lineColor;
	var slope, slopeText, slopeIcon, slopeColor, slopeColorText;
	var spdUnitText, altUnitText, distUnitText, tempUnitText;
  var tempe;
	
	var sc = new SunCalc();
	var zoneInfo;
  var restingHR,sporttype;
	
    function initialize() {
        DataField.initialize();
        
        display = new Display();
        
        altitude = 0.0f;
        averageCadence = 0.0f;
        averageSpeed = 0.0f;
        currentCadence = 0;
        currentPower = 0;
        currentHeading = null;
        currentHeartRate = null;
        currentSpeed = 0.0f;
        elapsedDistance = 0.0f;        
        elapsedTime = 0.0f;
        maxCadence = 0.0f;
        maxSpeed = 0.0f;
        timerTime = 0.0f;
        totalAscent = 0.0f;
        
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

        previousAltitude = -10000;
        bufferPos = 0;
        bufferSize = 5;
        buffer = new [bufferSize];
        for (var i = 0; i < bufferSize; i++) {
          buffer[i] = null;
        }
        
        font = Ui.loadResource(Rez.Fonts.text);
        fontsport = Ui.loadResource(Rez.Fonts.sport);
        
        sporttype = UserProfile.getCurrentSport();
        zoneInfo = UserProfile.getHeartRateZones(sporttype);
        var profile = UserProfile.getProfile();
        restingHR = profile.restingHeartRate;
    }
    
    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        return;
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
      if(info has :currentPower){
        if(info.currentPower != null){
          currentPower = info.currentPower;
        } else {
          currentPower = 0.0f;
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
      
      temperature = getTemperature();
    
      if(currentSpeed > 0 && previousAltitude > -10000){
        buffer[bufferPos] = (altitude - previousAltitude) / currentSpeed;
        bufferPos++;

          if (bufferPos == bufferSize) {
            bufferPos = 0;
          }

          var slopeSum = 0.0;
          var slopeNum = 0;

          for (var i = 0; i < bufferSize; i++) {
            if (buffer[i] != null) {
              slopeNum++;
              slopeSum += buffer[i];
            }
          }
          slope = 100 * slopeSum / slopeNum;
      }
      previousAltitude = altitude;
      
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
    function onUpdate(dc as Gfx.Dc) {
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

      var centerX = dc.getWidth() / 2;
      var centerY = dc.getHeight() / 2;
      var halfr = centerY - 4;
      var line1Y = centerY;
      var line2Y = dc.getHeight()* 2 / 3;
      var line3Y = dc.getHeight()* 5 / 6;
      var width = dc.getWidth();
      var height = dc.getHeight();

      var systemSettings = Sys.getDeviceSettings();
      if (systemSettings.paceUnits == Sys.UNIT_STATUTE) {
        spdUnitText = "mph";
        averageSpeed /= 1.609344;
        currentSpeed /= 1.609344;
        maxSpeed /= 1.609344;
      } else {
        spdUnitText = "km/h";
      }
      if (systemSettings.elevationUnits == Sys.UNIT_STATUTE) {
        altUnitText = "ft";
        altitude *= 3.2808399;
        totalAscent *= 3.2808399;
      } else {
        altUnitText = "m";
      }
      if (systemSettings.distanceUnits == Sys.UNIT_STATUTE) {
        distUnitText = "mi";
        elapsedDistance /= 1.609344;
      } else {
        distUnitText = "km";
      }
      if(temperature != null){
        if (systemSettings.temperatureUnits == Sys.UNIT_STATUTE) {
          tempUnitText = " °F";
          temperature = temperature * 9 / 5 + 32;
        } else {
          tempUnitText = " °C";
        }
      }

      slopeText = "0";
      slopeIcon = " ";
      slopeColor = -1;
      bgColor = getBackgroundColor();
      if(bgColor == Gfx.COLOR_WHITE){
        slopeColorText = Gfx.COLOR_BLACK;
      } else { 
        slopeColorText = Gfx.COLOR_WHITE;
      }

      if (slope.abs() >= 10) {
            slopeText = slope.abs().format("%d");
      } else if (slope != 0) {
            slopeText = slope.abs().format("%.1f");
      } 
      if (slope <= -5) {
        slopeIcon = "V";
        slopeColor = Gfx.COLOR_BLUE;
      } else if (slope < 0) {
        slopeIcon = "T";
        if (slope <= -2) {
          slopeColor = Gfx.COLOR_GREEN;
        }
      } else if (slope >= 5) {
        slopeIcon = "U";
        slopeColor = Gfx.COLOR_DK_RED;
        slopeColorText = Gfx.COLOR_WHITE;
      } else if (slope > 0) {
        slopeIcon = "S";
        if (slope >= 2) {
          slopeColor = Gfx.COLOR_ORANGE;
        }
      }
      
      if (elapsedDistance >= 100) {
        elapsedDistanceText = elapsedDistance.format("%.1f");
      } else {
        elapsedDistanceText = elapsedDistance.format("%.2f");
      }
      
      clockTime = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		
      txtColor = Gfx.COLOR_BLACK;
      lineColor = Gfx.COLOR_LT_GRAY;
      if (bgColor == Gfx.COLOR_BLACK) {
        txtColor = Gfx.COLOR_WHITE;
        lineColor = Gfx.COLOR_DK_GRAY;
      }
      dc.setColor(txtColor, -1);
      dc.clear();

  

      curSpeed = currentSpeed.format("%d");
      if(currentSpeed < 10 && currentSpeed > 0.5){
        curSpeed = currentSpeed.format("%.1f");
      }

		  dc.drawText(centerX, centerY+display.halfShift, Gfx.FONT_NUMBER_THAI_HOT, curSpeed, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
      dc.drawText(centerX+display.spdUnitTextOffset, centerY+display.halfShift-34, font, spdUnitText, Gfx.TEXT_JUSTIFY_LEFT);

      textWithIconOnCenter(dc, altitude.format("%d"), "G", altUnitText, (line2Y - centerY), centerY, Gfx.FONT_MEDIUM, 10);
      textWithIconOnCenter(dc, totalAscent.format("%d"), "H", altUnitText, width- (line2Y - centerY), centerY, Gfx.FONT_MEDIUM, 10);
      var middleSegment = Application.Properties.getValue("middleSegment");
      
      if(middleSegment == 5){
        dc.setColor(slopeColor,-1);
        dc.fillRectangle(centerX-(line2Y - centerY+30)/2, centerY+2, (line2Y - centerY+30), line2Y - centerY - 3);
        dc.setColor(slopeColorText, -1);
        textWithIconOnCenter(dc, slopeText, slopeIcon, "%", centerX, centerY, Gfx.FONT_MEDIUM, 10);
      }
      
      dc.setColor(txtColor, -1);					
      textWithIconOnCenter(dc, elapsedDistanceText, "", distUnitText, centerX, line2Y+(line3Y-line2Y-dc.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_MILD))/2, Gfx.FONT_SYSTEM_NUMBER_MILD, display.distShift);  


      var leftSegment = Application.Properties.getValue("leftSegment");
      var arcSegment = Application.Properties.getValue("arcSegment");
      var colorA = txtColor;
      var colorB = lineColor;
      if (currentHeartRate != null && (leftSegment == 1 || middleSegment == 1)) {
        if (currentHeartRate >= zoneInfo[4]) {
          colorA = 0xFFFFFF;
          colorB = 0xFF0000;
        } else if (currentHeartRate >= zoneInfo[3]) {
          colorA = 0x000000;
          colorB = 0xFFAA00;
        } else if (currentHeartRate >= zoneInfo[2]) {
          colorA = 0x000000;
          colorB = 0x00FF00;
        } else if (currentHeartRate >= zoneInfo[1]) {
          colorA = 0x000000;
          colorB = 0x00AAFF;
        } 
        if (leftSegment == 1) {
          dc.setColor(colorA, colorB);
          dc.drawText(display.hrOffset, line2Y, fontsport, "  I ", Gfx.TEXT_JUSTIFY_RIGHT);
          dc.setColor(txtColor, -1);
          dc.drawText(display.hrOffset + 2, line2Y -2, Gfx.FONT_MEDIUM, currentHeartRate.format("%d"), Gfx.TEXT_JUSTIFY_LEFT);
		    }
        if (middleSegment == 1) {
          dc.setColor(colorB, -1);
          dc.fillRectangle(centerX-(line2Y - centerY+30)/2, centerY+2, (line2Y - centerY+30), line2Y - centerY - 3);
          dc.setColor(txtColor, -1);
          textWithIconOnCenter(dc, currentHeartRate.format("%d"), "I", "", centerX, centerY, Gfx.FONT_MEDIUM, 10);
        }
		  }
		
      var rightSegment = Application.Properties.getValue("rightSegment");
      var toggleMinMax = Application.Properties.getValue("toggleMinMax");
      var minMaxSegment = Application.Properties.getValue("minMaxSegment");
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
        dc.drawText(width-display.hrOffset, line2Y, fontsport, " W  ", Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(txtColor, -1);
        dc.drawText(width-display.hrOffset-2, line2Y -2, Gfx.FONT_MEDIUM, currentCadence.format("%d"), Gfx.TEXT_JUSTIFY_RIGHT);
		  }

      if (leftSegment == 2 || rightSegment == 2) {
        var timerTimeText = formatTime(timerTime);
        if (leftSegment == 2) {
          dc.drawText(display.x2Offset, line2Y -2, Gfx.FONT_SMALL, timerTimeText, Gfx.TEXT_JUSTIFY_LEFT);
        }
        if (rightSegment == 2) {
          dc.drawText(width-display.x2Offset, line2Y -2, Gfx.FONT_SMALL, timerTimeText, Gfx.TEXT_JUSTIFY_RIGHT);
        }
      }
		
      if (leftSegment == 3 || rightSegment == 3 || middleSegment == 3) {
        var elapsedTimeText = formatTime(elapsedTime);
        if (leftSegment == 3) {
          dc.drawText(display.x2Offset, line2Y -2, Gfx.FONT_SMALL, elapsedTimeText, Gfx.TEXT_JUSTIFY_LEFT);
        }
        if (rightSegment == 3) {
          dc.drawText(width-display.x2Offset, line2Y -2, Gfx.FONT_SMALL, elapsedTimeText, Gfx.TEXT_JUSTIFY_RIGHT);
        }
        if (middleSegment == 3) {
          textWithIconOnCenter(dc, elapsedTimeText, "", "", centerX, centerY, Gfx.FONT_MEDIUM, 10);
        }
      }

      if (leftSegment == 4 || rightSegment == 4 || middleSegment == 4) {
        var powerText = currentPower.format("%d");
        if (leftSegment == 4) {
          dc.setColor(txtColor, -1);
          dc.drawText(display.hrOffset, line2Y+1, fontsport, "C", Gfx.TEXT_JUSTIFY_RIGHT);
          dc.setColor(txtColor, -1);
          dc.drawText(display.hrOffset+2, line2Y -2, Gfx.FONT_SMALL, powerText, Gfx.TEXT_JUSTIFY_LEFT);
        }
        if (rightSegment == 4) {
          dc.setColor(txtColor, -1);
          dc.drawText(width-display.hrOffset+1, line2Y+1, fontsport, "C", Gfx.TEXT_JUSTIFY_LEFT);
          dc.setColor(txtColor, -1);
          dc.drawText(width-display.hrOffset-1, line2Y-2, Gfx.FONT_SMALL, powerText, Gfx.TEXT_JUSTIFY_RIGHT);
        }
        if (middleSegment == 4) {
          dc.setColor(txtColor, -1);
          textWithIconOnCenter(dc, powerText, "C", "", centerX, centerY, Gfx.FONT_MEDIUM, 10);
        }
      }

		  dc.drawText(centerX, display.topShift, Gfx.FONT_SMALL, clockTime.hour + ":" + clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

      var showCadence = minMaxSegment == 1;
      if(toggleMinMax){
        showCadence = clockTime.sec % 6 < 3;
      }
      if (showCadence) {
        dc.drawText((line2Y - centerY), centerY+display.halfShift+4, Gfx.FONT_MEDIUM, averageCadence.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText((line2Y - centerY), centerY+display.halfShift-12, fontsport, "X", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width-(line2Y - centerY), centerY+display.halfShift+4, Gfx.FONT_MEDIUM, maxCadence.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width-(line2Y - centerY), centerY+display.halfShift-12, fontsport, "Y", Gfx.TEXT_JUSTIFY_CENTER);
      } else {
        dc.drawText((line2Y - centerY), centerY+display.halfShift+4, Gfx.FONT_MEDIUM, averageSpeed.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText((line2Y - centerY), centerY+display.halfShift-12, fontsport, "D", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width-(line2Y - centerY), centerY+display.halfShift+4, Gfx.FONT_MEDIUM, maxSpeed.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width-(line2Y - centerY), centerY+display.halfShift-12, fontsport, "E", Gfx.TEXT_JUSTIFY_CENTER);
      }
		
      var lineSunset = line3Y+display.tempSunsetShift;

      if (temperature != null) {
        if(tempe == null){
          //without tempe blue
          dc.setColor(0x00AAFF, -1);
        }else{
          //with tempe red
          dc.setColor(0xFF0000, -1);
        }
        
        dc.drawText(centerX - display.sunsetX, lineSunset, fontsport, "B", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(txtColor, -1);
        dc.drawText(centerX - display.sunsetX + 2, lineSunset, font, temperature.format("%d") + tempUnitText, Gfx.TEXT_JUSTIFY_LEFT);
      }
      var sunsetText = "-:--";
      if (sunset != null) {
        sunsetText = sunset.hour + ":" + sunset.min.format("%02d");
      }	
      // sunsetText = "19:38";line3Y+2
      dc.setColor(0xFFAA00, -1);
      dc.drawText(centerX + display.sunsetX, lineSunset, fontsport, "A", Gfx.TEXT_JUSTIFY_RIGHT);
      dc.setColor(txtColor, -1);
      dc.drawText(centerX + display.sunsetX + 2, lineSunset, font, sunsetText, Gfx.TEXT_JUSTIFY_LEFT);

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
        dc.drawText(display.compasOffset - compass, height-18, fontsport, "RQRJRKRLRMRNRORPRQRJRKR", Gfx.TEXT_JUSTIFY_LEFT);
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
        dc.fillRectangle(display.offsetBattery + i * 3, display.topShift + 8 - i * 2, 2, i * 2 + 2);
      }
      
      dc.setColor(txtColor, -1);
      var batteryX = width-display.offsetBattery;
      dc.drawRoundedRectangle(batteryX, display.topShift +2, 19, 9, 1);		
      dc.drawRectangle(batteryX+19, display.topShift + 5, 1, 3);		
      var systemStats = Sys.getSystemStats();
      var battery = systemStats.battery / 25 + 1;
      battery = battery.toNumber();
      if (battery > 4) {
        battery = 4;
      }
      for (var i = 0; i < battery; i++) {
        dc.setColor(systemStats.battery > 10 ? 0x00FF00 : 0xFF0000, bgColor);
        dc.fillRectangle(batteryX + 2 + i * 4, display.topShift + 4, 3, 5);
      }
      

      if(arcSegment == 1){
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
        dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180, 0);
        dc.setColor(speedColor, -1);
        dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180, 180 - speed);
        dc.setPenWidth(20);
        for (var i = 1; i < 12; i++) {
          dc.setColor(speed > i * step ? speedColor : lineColor, bgColor);
          dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180 - i * step, 180 - i * step - 1);
        }
      }
      if (arcSegment == 2) {
        if( restingHR == null){
          restingHR = 40;
        }
        
        if( currentHeartRate == null){
          currentHeartRate = 0;
        }
        colorB = lineColor;
        if (currentHeartRate >= zoneInfo[4]) {
          colorB = 0xFF0000;
        } else if (currentHeartRate >= zoneInfo[3]) {
          colorB = 0xFFAA00;
        } else if (currentHeartRate >= zoneInfo[2]) {
          colorB = 0x00FF00;
        } else if (currentHeartRate >= zoneInfo[1]) {
          colorB = 0x00AAFF;
        } 
          var step = 15;
          var hrate = (currentHeartRate - restingHR).toFloat() / (zoneInfo[5]- restingHR) * 180;
          hrate = hrate.toNumber();
          if (hrate > 180) {
            hrate = 180;
          }
          if (hrate < 0) {
            hrate = 0;
          }
          
          dc.setPenWidth(20);
          for (var i = 1; i < 12; i++) {
            dc.setColor(hrate >= i * step ? colorB : lineColor, bgColor);
            dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180 - i * step, 180 - i * step - 1);
          }
          dc.setPenWidth(11);
          dc.setColor(lineColor, -1);
          dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180, 0);
          
          if (hrate > 0) {
            dc.setPenWidth(10);
            dc.setColor(bgColor, -1);
            dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180, 0);
            dc.setColor(colorB, -1);
            dc.drawArc(centerX, centerY, halfr, Gfx.ARC_CLOCKWISE, 180, 180 - hrate);
          }
        }

      dc.setColor(lineColor, bgColor);
      dc.setPenWidth(1);
      dc.drawLine(0, line1Y, width, line1Y);

      dc.drawLine(0, line2Y, width, line2Y);
      
      dc.drawLine(0, line3Y, width, line3Y);
    }

    (:bigMemory)
    function getTemperature(){
      try
      {
        if(tempe == null){
          tempe = new TempeWidgetSensor(-1);  
        }else if(tempe.tmTemp != null){
            return tempe.iTemp;
        }
      } catch (ex)
      {
        System.println("Exception in TempeWidgetSensor: " + ex.getErrorMessage());
        tempe = null;
      }
      if ((tempe == null || tempe.tmTemp == null) && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
        // Set up the method with parameters
        var tempIter = Toybox.SensorHistory.getTemperatureHistory({
        :period => 1
        });
        if (tempIter != null) {
          return tempIter.next().data.toFloat();
        }
      }
    }

    (:smallMemory)
    function getTemperature(){
      
      if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
        // Set up the method with parameters
        var tempIter = Toybox.SensorHistory.getTemperatureHistory({
        :period => 1
        });
        if (tempIter != null) {
          return tempIter.next().data.toFloat();
        }
      }
    }
}
