import Toybox.Ant;
import Toybox.AntPlus;

/*
    Copy from
    https://github.com/shane1974/TempeWidget/blob/master/source/TempeWidgetSensor.mc
    Thanks Shane!
*/
(:bigMemory)
class TempeWidgetSensor
{
    var antChannel; //Ant.GenericChannel

    var searching;
    var deviceCfg;
    var antid=0;        //the actual device found
    var idSearch = 0;
    var chanAssign;
         
    //---------------------------------
    //used for dealing with Ant+ channel not always opening properly
    var durMsgTimeout = 15000; 

    //---------------------------------
    function initialize(id)
    {
        idSearch = id;
        if (id == -1) {id = 0;}
        // Get the channel
        var chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PLUS);
        antChannel = new Ant.GenericChannel(method(:onMessage), chanAssign);

        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => id,
            :deviceType => 25, //profile type
            :transmissionType => 0,
            :messagePeriod => 65535,
            :radioFrequency => 57,             //Ant+ Frequency
            :searchTimeoutLowPriority => 6,    //Timeout in 15s 
            :searchTimeoutHighPriority => 0,    // Timeout disabled
            :searchThreshold => 0} );          //Pair to all transmitting sensors
            
        antChannel.setDeviceConfig(deviceCfg);

        open();
    }


//---------------------------------
    var iTemp;      //in 100ths degree C
    var minTemp;      //in 100ths degree C
    var maxTemp;      //in 100ths degree C
    var offsetTemp; //offset in 100ths degree C
    var tmTemp;     //time of last temperature reading
    var batteryStatus;
    var payload;
    
    function parsePayload()
    {
        var pg = payload[0];

        //var pageNumber = (payload[0] & 0xFF);
        //System.println("var pg & 0xFF : " + pageNumber);

        //System.println("var pg  : " + pg);

        if (pg == 1)
        {

            var temp = ((payload[4] & 0xF0) << 4) | payload[3];
            minTemp = (temp == 0x800 ? null
                : (temp & 0x800) == 0x800 ? -(0xFFF - temp)
                : temp) * 0.1f;

            //maxTemp = (payload[5] << 4) | (payload[4] & 0x0F);
            temp = (payload[5] << 4) | (payload[4] & 0x0F);
            maxTemp = (temp == 0x800 ? null
                : (temp & 0x800) == 0x800 ? -(0xFFF - temp)
                : temp) * 0.1f;

            //iTemp = payload[6] + (payload[7]<<8);
            temp = (payload[7] << 8) | payload[6];
            iTemp = (temp == 0x8000 ? null
                : (temp & 0x8000) == 0x8000 ? -(0xFFFF - temp)
                : temp) * 0.01f;

            tmTemp = System.getTimer();
            System.println("temperature: " + iTemp.format("%.1f"));
        } else if (pg == 82)
        {
            batteryStatus = (payload[7] >> 4) & 0x07; // Battery status

            /*
            var courseBatteryVoltage = (payload[7]) & 0x0F; // Course Battery Volate
            System.println("courseBatteryVoltage : " + courseBatteryVoltage);

            var fracBatteryVoltage = (payload[6] / 256 ) ; // Course Battery Volate
            System.println("fracBatteryVoltage : " + fracBatteryVoltage);
            
            var batteryVoltage = (courseBatteryVoltage + fracBatteryVoltage ) ; // Course Battery Volate
            System.println("batteryVoltage : " + batteryVoltage);
            */

            //System.println("batteryStatus : " + batteryStatus);
            //if (batteryStatus == null) {batteryStatus = 6;}
            //System.println("batteryStatus after conversion : " + batteryStatus);

        }
    }

    //---------------------------------
    // just minimal reset;
    function resetSensor(id)
    {
        idSearch = id;
        if (id == -1) {id = 0;}

        antChannel.close(); //or release?
        deviceCfg.deviceNumber = id;
        antChannel.setDeviceConfig(deviceCfg);
        open();
    }


    function isValid() {return(searching==false);}


    function open()
    {
        System.println(strTime(System.getClockTime(),true) + " open channel: "+deviceCfg.deviceNumber);
        antChannel.open();
        searching = true;
    }
    //---------------------------------
    function closeSensor()
    {
        antChannel.release(); //automatically closes
    }

    function strTime(clockTime,fLong)
    {    
        var hour, min;

        hour = clockTime.hour % 12;
        hour = (hour == 0) ? 12 : hour;
        min = clockTime.min;

        var str = Lang.format("$1$:$2$",[hour, min.format("%02d")]);

        if (fLong)
        {
            //var ampm = (clockTime.hour < 12) ? "a" : "p";
            str = str + Lang.format(":$1$",[clockTime.sec.format("%02d")]);
        }
        return (str);
    }

    //---------------------------------
    //System.println("Just created payload var");

    function onMessage(msg as Message) as Void
    {
        payload = msg.getPayload();

        //System.println("Ant.MSG_ID_CHANNEL_RESPONSE_EVENT " + Ant.MSG_ID_CHANNEL_RESPONSE_EVENT);
        //System.println("Ant.MSG_ID_BROADCAST_DATA " + Ant.MSG_ID_BROADCAST_DATA);
        //System.println("msg.messageId " + msg.messageId);

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId )
        {
            // Were we searching?
            if (searching)
            {
                searching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = antChannel.getDeviceConfig();
                antid = msg.deviceNumber;
                System.println("Tempe found - antid: " + antid);
            }
            parsePayload();
        }
        else if(Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId)
        {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF))
            {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF))
                {
                    open();  //technically it should be closed at this point
                }
                else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF) )
                {
                    searching = true;
                }
            }
        }
    }
}