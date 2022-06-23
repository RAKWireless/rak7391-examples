#include <Wire.h>
#include <SPI.h>
#include "CayenneLPP.h"
#include <LoRaWan-RAK4630.h>
#include <SparkFun_SHTC3.h>     // Click here to get the library: http://librarymanager/All#SparkFun_SHTC3

//#define SENSOR_MOCK
#define SEND_EVERY                      20000

#define LORAWAN_DATARATE                DR_3
#define LORAWAN_ADR                     LORAWAN_ADR_OFF
#define LORAWAN_REGION                  LORAMAC_REGION_US915
#define LORAWAN_TX_POWER                TX_POWER_15
#define JOINREQ_NBTRIALS                3
#define LORAWAN_CLASS                   CLASS_A
#define LORAWAN_PORT                    1
#define LORAWAN_CONFIRM                 LMH_UNCONFIRMED_MSG

// 70B3D57ED00522DD
// 0000000000000000
// 5B48104478F58466EEDEE4E0F91D1D5E

#define LORAWAN_LOCAL_DEVEUI            { 0x70, 0xB3, 0xD5, 0x7E, 0xD0, 0x05, 0x22, 0xDD }
#define LORAWAN_LOCAL_APPEUI            { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
#define LORAWAN_LOCAL_APPKEY            { 0x5B, 0x48, 0x10, 0x44, 0x78, 0xF5, 0x84, 0x66, 0xEE, 0xDE, 0xE4, 0xE0, 0xF9, 0x1D, 0x1D, 0x5E }


CayenneLPP payload(51);
uint32_t last_block = 9999;

// ----------------------------------------------------------------------------
// Sensor
// ----------------------------------------------------------------------------

SHTC3 shtc3;

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

// ----------------------------------------------------------------------------
// LoraWAN
// ----------------------------------------------------------------------------

void lorawan_rx_handler(lmh_app_data_t * data) {

    #ifdef DEBUG
        Serial.printf(
            "[LORA] LoRa Packet received on port %d, size:%d, rssi:%d, snr:%d, data:%s\n",
            data->port, data->buffsize, data->rssi, data->snr, data->buffer
        );
    #endif

}

/**
 * @brief LoRa function for handling HasJoined event.
 */
void lorawan_has_joined_handler(void) {

    lmh_error_status ret = lmh_class_request((DeviceClass_t) LORAWAN_CLASS);
    if (ret == LMH_SUCCESS) {

        #ifdef DEBUG
            Serial.println("[LORA] LoRaWAN Joined");
        #endif

    }

}

static void lorawan_join_failed_handler(void) {
    #ifdef DEBUG
        Serial.println("[LORA] OTAA join failed!");
        Serial.println("[LORA] Check your EUI's and Keys's!");
        Serial.println("[LORA] Check if a Gateway is in range!");
    #endif
}

void lorawan_confirm_class_handler(DeviceClass_t Class) {

    #ifdef DEBUG
        Serial.printf("[LORA] Switch to class %c done\n", "ABC"[Class]);
    #endif

    // Inform the server that switch has occurred ASAP
    lmh_app_data_t m_lora_app_data = {nullptr, 0, LORAWAN_PORT, 0, 0};
    lmh_send(&m_lora_app_data, LORAWAN_CONFIRM);

}

static lmh_callback_t lora_callbacks = {
    BoardGetBatteryLevel, BoardGetUniqueId, BoardGetRandomSeed,
        lorawan_rx_handler, lorawan_has_joined_handler, lorawan_confirm_class_handler, lorawan_join_failed_handler
};

bool lorawanSetup() {

    lora_rak4630_init();
    
    // Setup the EUIs and Keys
    unsigned char deveui[] = LORAWAN_LOCAL_DEVEUI;
    unsigned char appeui[] = LORAWAN_LOCAL_APPEUI;
    unsigned char appkey[] = LORAWAN_LOCAL_APPKEY;
    lmh_setDevEui(deveui);
    lmh_setAppEui(appeui);
    lmh_setAppKey(appkey);

    // Init structure
    lmh_param_t lora_param_init = {
        LORAWAN_ADR, LORAWAN_DATARATE, LORAWAN_PUBLIC_NETWORK, JOINREQ_NBTRIALS, LORAWAN_TX_POWER, LORAWAN_DUTYCYCLE_OFF
    };

    // Initialize LoRaWan
    unsigned long err_code = lmh_init(&lora_callbacks, lora_param_init, true, (DeviceClass_t) LORAWAN_CLASS, (LoRaMacRegion_t) LORAWAN_REGION);
    #ifdef DEBUG
        if (err_code != 0) {
            Serial.printf("[LORA] LoRa init failed with error: %d\n", err_code);
        } else {
            unsigned char deveui[] = LORAWAN_LOCAL_DEVEUI;
            Serial.printf("[LORA] Device EUI: %02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X\n",
                deveui[0], deveui[1], deveui[2], deveui[3],
                deveui[4], deveui[5], deveui[6], deveui[7]
            );
        }
    #endif

    // Start Join procedure
    if (err_code == 0) {
        lmh_join();
    }

    return (err_code == 0);

}

bool lorawanSend(uint8_t * data, uint8_t len) {

    if (lmh_join_status_get() != LMH_SET) {
        //Not joined, try again later
        return false;
    }

    #ifdef DEBUG
        Serial.print("[LORA] Sending frame: ");
        for (unsigned char i=0; i<len; i++) {
            Serial.printf("%02X", data[i]);
        }
        Serial.println();
    #endif

    // Build message structure
    lmh_app_data_t m_lora_app_data = {data, len, LORAWAN_PORT, 0, 0};
    lmh_error_status error = lmh_send(&m_lora_app_data, LORAWAN_CONFIRM);

    return (error == LMH_SUCCESS);

}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------

void send() {

    shtc3.update();
  
  if (shtc3.lastStatus == SHTC3_Status_Nominal) {

    if (shtc3.passRHcrc) {
      Serial.printf("[SHTC3] Humidity: %.1f%%\n", shtc3.toPercent()); 
    } else {
      Serial.println("[SHTC3] Humidity reading ERROR");
            return; 
    }
    
    if (shtc3.passTcrc) {
      Serial.printf("[SHTC3] Temperature: %.1fC\n", shtc3.toDegC());  
    } else {
      Serial.println("[SHTC3] Temperature reading ERROR");
            return; 
    }
  
  } else {
      Serial.printf("[SHTC3] Update failed, error: %d\n", shtc3.lastStatus);
        return;
  }

    payload.reset();
    payload.addTemperature(1, shtc3.toDegC());
    payload.addRelativeHumidity(2, shtc3.toPercent());
    lorawanSend(payload.getBuffer(), payload.getSize());

}

void setup() {
    
    // Initialize the built in LED
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, LOW);

    // Init debug line
    Serial.begin(115200);
    while ((!Serial) && (millis()<5000)) delay(100);
    
    // Init sensor
    shtc3_setup();

    // Init Radio
    lorawanSetup();

}

void loop() {

    uint32_t block = millis() / SEND_EVERY;
    if (block != last_block) {
        last_block = block;
        send();
    }

}
