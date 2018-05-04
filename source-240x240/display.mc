using Toybox.Graphics as Gfx;

class Display {
  function render (dc, bike) {
    dc.drawText(120, 80, Gfx.FONT_NUMBER_THAI_HOT, bike.currentSpeed.format("%d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
	dc.drawText(156, 46, bike.font, bike.spdUnitText, Gfx.TEXT_JUSTIFY_LEFT);

	bike.textWithIconOnCenter(dc, bike.altitude.format("%d"), "G", bike.altUnitText, 40, 120, Gfx.FONT_MEDIUM, 10);
	bike.textWithIconOnCenter(dc, bike.totalAscent.format("%d"), "H", bike.altUnitText, 196, 120, Gfx.FONT_MEDIUM, 10);
		
	dc.setColor(bike.slopeColor, -1);
	dc.fillRectangle(90, 120, 60, 34);
	dc.setColor(bike.slopeColorText, -1);
	bike.textWithIconOnCenter(dc, bike.slopeText, bike.slopeIcon, "%", 120, 120, Gfx.FONT_MEDIUM, 10);

	dc.setColor(bike.txtColor, -1);					
	bike.textWithIconOnCenter(dc, bike.elapsedDistanceText, "", bike.distUnitText, 120, 158, Gfx.FONT_NUMBER_MEDIUM, 18);    
  }
}