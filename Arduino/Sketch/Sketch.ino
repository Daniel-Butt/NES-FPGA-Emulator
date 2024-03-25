
// Source adapted from https://github.com/wd5gnr/VidorFPGA

#include <wiring_private.h>
#include "jtag.h"
#include "defines.h"

#include <Wire.h>
#include <IRremote.h>
#define IR_RECEIVE_PIN 19


// uint8_t old_msg;
// uint8_t msg;

// unsigned long lastTime;
// unsigned long dt;

bool led_state = HIGH;

//int a = 0;

// const PROGMEM char audioData[110000] = {
//                                         #include "mainSong.h"
//                                        };

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


// void changeAudio(){
//   writeFPGA(audioData[a]);
//   a++;

//   if (a >= 110000){
//     a = 0;
//   }
// }

void setup()
{

  Serial.begin(9600);
  //pinMode(8, INPUT);
  IrReceiver.begin(IR_RECEIVE_PIN);

  // pinMode(0, INPUT);
  // pinMode(1, INPUT);
  // pinMode(2, INPUT);
  // pinMode(3, INPUT);
  // pinMode(4, INPUT);
  // pinMode(5, INPUT);
  // pinMode(6, INPUT);
  // pinMode(7, INPUT);
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

  //writeFPGA(0);
  //digitalWrite(3, 1);

  // pinMode(8, INPUT_PULLUP);
  // attachInterrupt(digitalPinToInterrupt(8), changeAudio, RISING);

  //Wire.begin(1); 

  //Wire.onReceive(receiveEvent);
  //digitalWrite(7, HIGH);

  // initialize and program the fpga
  setup_fpga();

  Serial.println("FPGA Started");

  // for (int i = 0; i < 100000; i++){
  //   data[i] = i;
  // }
}

// void receiveEvent(int bytes) {
//   msg = Wire.read();    // read one character from the I2C
// }


void loop()
{
  led_state = !led_state;
  digitalWrite(LED_BUILTIN, led_state);


  if (IrReceiver.decode()) {
    IrReceiver.resume();

    uint16_t c = IrReceiver.decodedIRData.command;

    switch (c) {
      case 69:
        Serial.println("start");
        writeFPGA(8);
        break;

      case 70:
        Serial.println("select");
        writeFPGA(4);
        break;

      case 22:
        Serial.println("A");
        writeFPGA(1);
        break;

      case 13:
        Serial.println("B");
        writeFPGA(2);
        break;

      case 8:
        Serial.println("left");
        writeFPGA(64);
        break;

      case 24:
        Serial.println("up");
        writeFPGA(16);
        break;

      case 90:
        Serial.println("right");
        writeFPGA(128);
        break;

      case 82:
        Serial.println("down");
        writeFPGA(32);
        break;

      default:
        writeFPGA(0);
        break;
    }
  }
  else{
    writeFPGA(0);
  }


  // if (Serial.available() > 0) {
  //   // read the incoming byte:
  //   char b = Serial.read();

  //   if (b == 'a'){
  //     Serial.println("start");
  //     writeFPGA(8);
  //   }
  //   else if (b == 'w'){
  //     Serial.println("up");
  //     writeFPGA(16);
  //   }
  //   else if (b == 's'){
  //     Serial.println("down");
  //     writeFPGA(32);
  //   }
  //   else{
  //     writeFPGA(0);
  //   }
    
  // }

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

  // if (msg != old_msg){
  //   old_msg = msg;
    
  //   unsigned long currentTime = micros();

  //   dt = currentTime - lastTime;

  //   lastTime = currentTime;

  //   Serial.println(dt);
  // }

  delay(200);

}
