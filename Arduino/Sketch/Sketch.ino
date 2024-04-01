
// Source adapted from https://github.com/wd5gnr/VidorFPGA

#include <wiring_private.h>
#include "jtag.h"
#include "defines.h"
#include <Wire.h>

uint8_t msg;
bool led_state = HIGH;

//hold right button if true
const bool USE_ORIGINAL_CONTROLLER = true;


void writeFPGA(uint8_t byte){

  digitalWrite(17, (byte & 1) > 0 ? HIGH : LOW);
  digitalWrite(6, (byte & 2) > 0 ? HIGH : LOW);
  digitalWrite(5, (byte & 4) > 0 ? HIGH : LOW);
  digitalWrite(4, (byte & 8) > 0 ? HIGH : LOW);
  digitalWrite(3, (byte & 16) > 0 ? HIGH : LOW);
  digitalWrite(2, (byte & 32) > 0 ? HIGH : LOW);
  digitalWrite(1, (byte & 64) > 0 ? HIGH : LOW);
  digitalWrite(0, (byte & 128) > 0 ? HIGH : LOW);
}


void receiveEvent(int bytes) {
  msg = Wire.read();    // read one character from the I2C
  Serial.println(msg, HEX);
  writeFPGA(msg);
}


// red - ground, black (brown) - 5V
const int PULSE = 12; // yellow 21
const int LATCH = 7; // green
const int DATA = 11; //white


uint8_t readController(){

  uint8_t data = 0;

  //toggle latch
  digitalWrite(LATCH, HIGH);
  
  digitalWrite(LATCH, LOW);
  

  for (int i = 0; i < 8; i++){

    //shift and sample data input
    data = data << 1;
    data += digitalRead(DATA);

    //toggle clock
    digitalWrite(PULSE, HIGH);
    
    digitalWrite(PULSE, LOW);
    
  }

  return ~data;
}


void setup()
{

  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, led_state);

  pinMode(0, OUTPUT);
  pinMode(1, OUTPUT);
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(17, OUTPUT);

  // initialize and program the fpga
  setup_fpga();

  Serial.println("FPGA Started");

  if (USE_ORIGINAL_CONTROLLER){
    pinMode(DATA, INPUT);
    pinMode(LATCH, OUTPUT);
    pinMode(PULSE, OUTPUT);
  }
  else{
    //setup I2C
    Wire.begin(1); 
    Wire.onReceive(receiveEvent);
  }
}


void loop()
{

  //Serial.println(digitalRead(11));

  if (USE_ORIGINAL_CONTROLLER){
    uint8_t control = readController();

    Serial.println(control, HEX);

    writeFPGA(control);
  }
  else{
    led_state = !led_state;
    digitalWrite(LED_BUILTIN, led_state);

    delay(1000);
  }  

}
