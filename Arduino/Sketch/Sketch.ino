
// Source adapted from https://github.com/wd5gnr/VidorFPGA

#include "jtag.h"
#include "defines.h"
#include <Wire.h>

uint8_t msg;
bool led_state = HIGH;


void writeFPGA(uint8_t byte){

  digitalWrite(0, (byte & 1) > 0 ? HIGH : LOW);
  digitalWrite(1, (byte & 2) > 0 ? HIGH : LOW);
  digitalWrite(2, (byte & 4) > 0 ? HIGH : LOW);
  digitalWrite(3, (byte & 8) > 0 ? HIGH : LOW);
  digitalWrite(4, (byte & 16) > 0 ? HIGH : LOW);
  digitalWrite(5, (byte & 32) > 0 ? HIGH : LOW);
  digitalWrite(6, (byte & 64) > 0 ? HIGH : LOW);
  digitalWrite(7, (byte & 128) > 0 ? HIGH : LOW);
}


void receiveEvent(int bytes) {
  msg = Wire.read();    // read one character from the I2C
  writeFPGA(msg);
}


void setup()
{

  Serial.begin(9600);

  pinMode(18, INPUT);
  pinMode(9, INPUT);
  pinMode(10, INPUT);
  pinMode(11, INPUT);
  pinMode(12, INPUT);
  pinMode(13, INPUT);
  pinMode(14, INPUT);
  pinMode(15, INPUT);
  pinMode(LED_BUILTIN, OUTPUT);

  pinMode(0, OUTPUT);
  pinMode(1, OUTPUT);
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(7, OUTPUT);

  // setup I2C
  Wire.begin(1); 
  Wire.onReceive(receiveEvent);

  // initialize and program the fpga
  setup_fpga();

  Serial.println("FPGA Started");
}


void loop()
{
  led_state = !led_state;
  digitalWrite(LED_BUILTIN, led_state);

  int hexCode = 0;

  for (int i = 8; i < 16; i++){

    if (i == 8){
      hexCode += digitalRead(18);
    }
    else{
      hexCode += digitalRead(i) << (i-8);
    }
  }

  Serial.println(hexCode, HEX);

  delay(1000);

}
