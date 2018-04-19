using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.SensorHistory;


class AnyaBikeView extends Ui.DataField {

    hidden var GPSaccuracy, sunset, temperature, altitude, averageCadence, averageSpeed, currentHeading, currentHeartRate, currentCadence, currentSpeed, elapsedDistance, elapsedTime, maxCadence, maxSpeed, totalAscent, totalDescent;
	hidden var compass;
	hidden var slope, sumAlt, countAlt, lastTM, lastDoneTM;
	hidden var memoryAlt;
	hidden var font, fontsport;
	hidden var bgColor, txtColor, lineColor;
	
	var sc = new SunCalc();
	var zoneInfo;
	
    function initialize() {
        DataField.initialize();
        altitude = 0.0f;
        averageCadence = 0.0f;
        averageSpeed = 0.0f;
        currentCadence = 0.0f;
        currentHeading = 0.0f;
        currentHeartRate = 50.0f;
        currentSpeed = 0.0f;
        elapsedDistance = 0.0f;
        elapsedTime = 0.0f;
        maxCadence = 0.0f;
        maxSpeed = 0.0f;
        totalAscent = 0.0f;
        totalDescent = 0.0f;
        temperature = 0.0f;
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
          altitude = info.altitude;
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
          currentHeading = 0.0f;
        }
      }
      if(info has :currentHeartRate){
        if(info.currentHeartRate != null){
          currentHeartRate = info.currentHeartRate;
        } else {
          currentHeartRate = 0.0f;
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
          currentCadence = 0.0f;
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
      if(info has :totalAscent){
        if(info.totalAscent != null){
          totalAscent = info.totalAscent;
        } else {
          totalAscent = 0.0f;
        }
      }
      if(info has :totalDescent){
        if(info.totalAscent != null){
          totalDescent = info.totalDescent;
        } else {
          totalDescent = 0.0f;
        }
      }
            
      var tempIter = Toybox.SensorHistory.getTemperatureHistory({
        :period => 1
      });
      if (tempIter != null) {
        temperature = tempIter.next().data;
      } else {
        temperature = 0.0f;
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

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
		/* currentSpeed += 2.13;
		if (currentSpeed > 65) {
		  currentSpeed = 0;
	    }

		slope = 4.8;
		altitude = 384;
		totalAscent = 234;*/
		    
        bgColor = getBackgroundColor();
        txtColor = Gfx.COLOR_BLACK;
        lineColor = Gfx.COLOR_LT_GRAY;
        if (bgColor == Gfx.COLOR_BLACK) {
          txtColor = Gfx.COLOR_WHITE;
          lineColor = Gfx.COLOR_DK_GRAY;
        }
        dc.setColor(txtColor, -1);
        dc.clear();
               
		dc.drawText(120, 80, Gfx.FONT_NUMBER_THAI_HOT, currentSpeed.format("%d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

		var slopeText = "0";
		var slopeIcon = " ";
		var slopeColor = -1;
		if (slope != 0) {
          slopeText = slope.abs().format("%.1f");
		}
		if (slope <= -10) {
		  slopeIcon = "V";
		  slopeColor = 0x55AAFF;
		  slopeText = slope.abs().format("%d");
		} else if (slope < 0) {
		  slopeIcon = "T";
		  if (slope <= -2) {
		    slopeColor = 0x55FF55;
		  }
		} else if (slope >= 10) {
		  slopeIcon = "U";
		  slopeColor = 0xFF5555;
		  slopeText = slope.format("%d");
		} else if (slope > 0) {
		  slopeIcon = "S";
		  if (slope >= 2) {
		    slopeColor = 0xFFAA55;
		  }
		}		
		textWithIconOnCenter(dc, altitude.format("%d"), "G", "m", 40, 120, Gfx.FONT_MEDIUM, 10);
		textWithIconOnCenter(dc, totalAscent.format("%d"), "H", "m", 196, 120, Gfx.FONT_MEDIUM, 10);
		dc.setColor(slopeColor, -1);
		dc.fillRectangle(90, 120, 60, 34);
		dc.setColor(txtColor, -1);
		textWithIconOnCenter(dc, slopeText, slopeIcon, "%", 120, 120, Gfx.FONT_MEDIUM, 10);

		
		var elapsedDistanceText = "";
		if (elapsedDistance >= 100) {
		  elapsedDistanceText = elapsedDistance.format("%.1f");
		} else {
		  elapsedDistanceText = elapsedDistance.format("%.2f");
		}
		
		textWithIconOnCenter(dc, elapsedDistanceText, "", "km", 120, 158, Gfx.FONT_NUMBER_MEDIUM, 18);

        var leftSegment = Application.Properties.getValue("leftSegment");
        if (leftSegment == 1) {
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
		  dc.drawText(24, 154, fontsport, "  I ", Gfx.TEXT_JUSTIFY_RIGHT);
		  dc.setColor(txtColor, -1);
		  dc.drawText(26, 152, Gfx.FONT_MEDIUM, currentHeartRate.format("%d"), Gfx.TEXT_JUSTIFY_LEFT);
		}
		
        var rightSegment = Application.Properties.getValue("rightSegment");
        if (rightSegment == 1) {
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
		  dc.drawText(216, 154, fontsport, " W  ", Gfx.TEXT_JUSTIFY_LEFT);
		  dc.setColor(txtColor, -1);
		  dc.drawText(214, 152, Gfx.FONT_MEDIUM, currentCadence.format("%d"), Gfx.TEXT_JUSTIFY_RIGHT);
		}
		
		if (leftSegment == 2 || rightSegment == 2) {
		  var elH = (elapsedTime / 3600) % 24;
		  var elM = (elapsedTime / 60) % 60;
		  var elS = elapsedTime % 60;
		  var elText = "-:--";
		  if (elH > 0) {
		    elText = elH.format("%d") + ":" + elM.format("%02d");
		  } else {
		    elText = elM.format("%d") + ":" + elS.format("%02d");
		  }
		  if (leftSegment == 2) {
		    dc.drawText(16, 152, Gfx.FONT_SMALL, elText, Gfx.TEXT_JUSTIFY_LEFT);
		  }
		  if (rightSegment == 2) {
		    dc.drawText(224, 152, Gfx.FONT_SMALL, elText, Gfx.TEXT_JUSTIFY_RIGHT);
		  }
		}

        var clockTime = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		dc.drawText(120, 30, Gfx.FONT_SMALL, clockTime.hour + ":" + clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

		if (clockTime.sec % 6 < 3 && rightSegment == 1) {
		  dc.drawText(50, 84, Gfx.FONT_MEDIUM, averageCadence.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
		  dc.drawText(50, 68, fontsport, "X", Gfx.TEXT_JUSTIFY_CENTER);
		  dc.drawText(190, 84, Gfx.FONT_MEDIUM, maxCadence.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);
		  dc.drawText(190, 68, fontsport, "Y", Gfx.TEXT_JUSTIFY_CENTER);
        } else {
		  dc.drawText(50, 84, Gfx.FONT_MEDIUM, averageSpeed.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
		  dc.drawText(50, 68, fontsport, "D", Gfx.TEXT_JUSTIFY_CENTER);
		  dc.drawText(190, 84, Gfx.FONT_MEDIUM, maxSpeed.format("%.1f"), Gfx.TEXT_JUSTIFY_CENTER);
		  dc.drawText(190, 68, fontsport, "E", Gfx.TEXT_JUSTIFY_CENTER);
        }

		dc.setColor(0x00AAFF, -1);
		dc.drawText(74, 200, fontsport, "B", Gfx.TEXT_JUSTIFY_RIGHT);
		dc.setColor(txtColor, -1);
		dc.drawText(76, 200, font, temperature.format("%d") + " °C", Gfx.TEXT_JUSTIFY_LEFT);
		var sunsetText = "-:--";
		if (sunset != null) {
		  sunsetText = sunset.hour + ":" + sunset.min.format("%02d");
		}	
		// sunsetText = "19:38";
		dc.setColor(0xFFAA00, -1);
		dc.drawText(144, 200, fontsport, "A", Gfx.TEXT_JUSTIFY_RIGHT);
		dc.setColor(txtColor, -1);
		dc.drawText(146, 200, font, sunsetText, Gfx.TEXT_JUSTIFY_LEFT);

	    var headDiff = currentHeading - compass;
	    if (headDiff > 180) {
	      headDiff = headDiff - 360;
	    }
	    compass += headDiff / 3;
	    if (compass < 0) {
	      compass += 360;
	    }
		dc.drawText(45 - compass, 222, fontsport, "RQRJRKRLRMRNRORPRQRJRKR", Gfx.TEXT_JUSTIFY_LEFT);

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
		dc.drawRoundedRectangle(152, 32, 19, 9, 1);		
		dc.drawRectangle(171, 35, 1, 3);		
		var systemStats = Sys.getSystemStats();
		var battery = systemStats.battery / 25 + 1;
		battery = battery.toNumber();
		if (battery > 4) {
		  battery = 4;
		}
		for (var i = 0; i < battery; i++) {
		  dc.setColor(systemStats.battery > 10 ? 0x00FF00 : 0xFF0000, bgColor);
 		  dc.fillRectangle(154 + i * 4, 34, 3, 5);
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
		var speedColor1 = 0x00AAFF;
		if (currentSpeed > speedRed) {
		  speedColor1 = 0xFF0000;
		} else if (currentSpeed > speedOrange) {
		  speedColor1 = 0xFFAA00;
		} else if (currentSpeed > speedGreen) {
		  speedColor1 = 0x00FF00;
		}
		
        dc.setPenWidth(10);
        dc.setColor(lineColor, -1);
	    dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180, 0);
        dc.setColor(speedColor1, -1);
	    dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180, 180 - speed);
        dc.setPenWidth(20);
	    for (var i = 1; i < 12; i++) {
	      dc.setColor(speed > i * step ? speedColor1 : lineColor, bgColor);
	      dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180 - i * step, 180 - i * step - 1);
        }

/*	    dc.setPenWidth(10);
		var speedColor1 = 0x00AAFF;
		var speedColor2 = 0x55FFFF;
		if (currentSpeed > speedRed) {
		  speedColor1 = 0xFF0000;
		  speedColor2 = 0xFF5555;
		} else if (currentSpeed > speedOrange) {
		  speedColor1 = 0xAA5500;
		  speedColor2 = 0xFFAA00;
		} else if (currentSpeed > speedGreen) {
		  speedColor1 = 0x00AA00;
		  speedColor2 = 0x55FF55;
		}
          var red = 1;
          var angle = 0;
          var fullPart = speed / step;
          fullPart = fullPart.toNumber();
          for (var i = 0; i < fullPart; i++) {
	        dc.setColor(red ? speedColor1 : speedColor2, bgColor);
	        dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180 - i * step, 180 - (i + 1) * step);
	        red = 1 - red;
          }
          if (180 - fullPart * step != 180 - speed) {
	        dc.setColor(red ? speedColor1 : speedColor2, bgColor);
	        dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180 - fullPart * step, 180 - speed);
	        dc.setColor(red ? 0x555555 : 0xAAAAAA, bgColor);
	        dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180 - speed, 180 - (fullPart + 1) * step);
	      } else {
	        dc.setColor(red ? 0x555555 : 0xAAAAAA, bgColor);
	        dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180 - fullPart * step, 180 - (fullPart + 1) * step);
	      }
	      red = 1 - red;	        
	      for (var i = fullPart + 1; i < 180 / step; i++) {
	        dc.setColor(red ? 0x555555 : 0xAAAAAA, bgColor);
	        dc.drawArc(120, 120, 116, Gfx.ARC_CLOCKWISE, 180 - i * step, 180 - (i + 1) * step);
	        red = 1 - red;	        
	      }
        */  

        dc.setColor(lineColor, bgColor);
        dc.setPenWidth(1);
        dc.drawLine(0, 120, 240, 120);

        dc.drawLine(0, 154, 240, 154);
        
        dc.drawLine(0, 198, 240, 198);
    }

}
