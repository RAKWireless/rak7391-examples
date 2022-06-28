/**
   @file rak5802_modbus_device.ino
   @author rakwireless.com
   @brief Simple ModBUS device based on a RAK5802 with an LED and a SHTC3 temperature & humidity sensor (RAK1902)
   @version 0.1
   @date 2022-02-20
   @copyright Copyright (c) 2022
**/

// ----------------------------------------------------------------------------
// Dependencies
// ----------------------------------------------------------------------------

#include <SparkFun_SHTC3.h> 		// Click here to get the library: http://librarymanager/All#SparkFun_SHTC3
#include <ArduinoRS485.h> 		    // Click here to get the library: http://librarymanager/All#ArduinoRS485
#include <ArduinoModbus.h> 		    // Click here to get the library: http://librarymanager/All#ArduinoModbus

// ----------------------------------------------------------------------------
// Configuration
// ----------------------------------------------------------------------------

#define MODBUS_ID					42
#define MODBUS_BAUD					9600
#define SENSOR_READ_INTERVAL		5000

// ----------------------------------------------------------------------------
// Globals
// ----------------------------------------------------------------------------

SHTC3 shtc3;

// ----------------------------------------------------------------------------
// Sensor
// ----------------------------------------------------------------------------

void shtc3_setup() {

	// Initialize I2C
	Wire.begin();

	// Initialize SHTC3
	Serial.printf("[SHTC3] Init, status: %d\n", shtc3.begin());
	Wire.setClock(400000);

	// Whenever data is received the associated checksum is calculated and verified so you can be sure the data is true
	if (shtc3.passIDcrc) {
		Serial.printf("[SHTC3] ID checksum passed, ID: 0x%04X\n", shtc3.ID);
	} else {
		Serial.println("[SHTC3] ID checksum failed");
	}

}

void shtc3_read(void) {
	
	shtc3.update();
	
	if (shtc3.lastStatus == SHTC3_Status_Nominal) {

		if (shtc3.passRHcrc) {
			ModbusRTUServer.holdingRegisterWrite(0, shtc3.toPercent());
			Serial.printf("[SHTC3] Humidity: %.1f%%\n", shtc3.toPercent());	
		} else {
			Serial.println("[SHTC3] Humidity reading ERROR");	
		}
		
		if (shtc3.passTcrc) {
			ModbusRTUServer.holdingRegisterWrite(1, shtc3.toDegC() * 100);
			Serial.printf("[SHTC3] Temperature: %.1fC\n", shtc3.toDegC());	
		} else {
			Serial.println("[SHTC3] Temperature reading ERROR");	
		}
	
	} else {
    	Serial.printf("[SHTC3] Update failed, error: %d\n", shtc3.lastStatus);
	}

}

// ----------------------------------------------------------------------------
// LED
// ----------------------------------------------------------------------------

void led_setup() {
	pinMode(LED_BUILTIN, OUTPUT);
	led_set(0);
}

void led_set(unsigned char value) {
	digitalWrite(LED_BUILTIN, value);
	ModbusRTUServer.coilWrite(0x00, value);
}

// ----------------------------------------------------------------------------
// Modbus
// ----------------------------------------------------------------------------

void modbus_setup() {
	
	// Enable RAK5802
	pinMode(WB_IO2, OUTPUT);
	digitalWrite(WB_IO2, HIGH);
	delay(300);
	
	// Init bus
  	if (!ModbusRTUServer.begin(MODBUS_ID, MODBUS_BAUD)) {
    	Serial.println("[MODBUS] Modbus RTU Server ERROR");
    	while (1);
  	}

	// One coil (LED) at address 0x00
	ModbusRTUServer.configureCoils(0x00, 1);

	// Two holding registers (hum and temp*100)
	ModbusRTUServer.configureHoldingRegisters(0x00, 2);

    Serial.println("[MODBUS] Modbus RTU Server OK");

}

void modbus_loop() {

 	ModbusRTUServer.poll();

  	// Set the coil (LED)
	led_set(ModbusRTUServer.coilRead(0x00));

}

// ----------------------------------------------------------------------------
// Arduino methods
// ----------------------------------------------------------------------------

void setup() {
	
	// Initialize PC debug
	Serial.begin(115200);
  	while ((!Serial) && (millis() < 5000)) delay(1);

	// Initialize SHTC3
	modbus_setup();

	// Initialize LED
	led_setup();

	// Initalize SHTC3 and populate the registers
	shtc3_setup();
	shtc3_read();

}

void loop() {

	// We update the sensor value every SENSOR_READ_INTERVAL
	static unsigned long last = 0;
	if (millis() - last > SENSOR_READ_INTERVAL) {
		last = millis();
		shtc3_read();
	}
  
	// Poll Modbus
	modbus_loop();
	
}
