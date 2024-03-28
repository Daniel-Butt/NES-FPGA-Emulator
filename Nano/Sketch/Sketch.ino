#include <Wire.h>

uint8_t hexCode;


void setup() {
  hexCode = 0;

  // change to controller inputs
  pinMode(0, INPUT);
  pinMode(1, INPUT);
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  pinMode(4, INPUT);
  pinMode(5, INPUT);
  pinMode(6, INPUT);
  pinMode(7, INPUT);

  //delay so FPGA board boots up before nano starts I2C
  delay(3000);

  Wire.begin(); 

}


void loop() {

  //change to read controller inputs
  hexCode += digitalRead(0);
  hexCode += digitalRead(1) << 1;
  hexCode += digitalRead(2) << 2;
  hexCode += digitalRead(3) << 3;
  hexCode += digitalRead(4) << 4;
  hexCode += digitalRead(5) << 5;
  hexCode += digitalRead(6) << 6;
  hexCode += digitalRead(7) << 7;

  //write controller input byte (like NES) over I2C
  Wire.beginTransmission(1);
  Wire.write(hexCode);             
  Wire.endTransmission();    

}