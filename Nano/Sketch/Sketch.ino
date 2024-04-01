#include <Wire.h>
#include <Arduino.h>

// Define the pin numbers for each button and joystick axis
const int buttonAPin = 9;
const int buttonBPin = 7;
const int selectButtonPin = 11;
const int startButtonPin = 10;
const int joystickXPin = A0; // X-axis
const int joystickYPin = A1; // Y-axis
const int joystickButton = 5;

// Define the bit positions for each button in the I2C message
const int buttonABit = 0;
const int buttonBBit = 1;
const int selectButtonBit = 2;
const int startButtonBit = 3;
const int upButtonBit = 4;
const int downButtonBit = 5; 
const int leftButtonBit = 6;
const int rightButtonBit = 7; 

const int LOWER = 100;
const int UPPER = 900;


void setup() {

  Serial.begin(9600);

  pinMode(LED_BUILTIN, OUTPUT);

  pinMode(buttonAPin, INPUT_PULLUP);
  pinMode(buttonBPin, INPUT_PULLUP);
  pinMode(selectButtonPin, INPUT_PULLUP);
  pinMode(startButtonPin, INPUT_PULLUP);

  //delay so FPGA board boots up before nano starts I2C
  delay(3000);

  Wire.begin(); 

}

bool led_state = HIGH;

void loop() {

  led_state = !led_state;
  digitalWrite(LED_BUILTIN, led_state);

  // Initialize the I2C message to 0
  uint8_t i2cMessage = 0;

  int x = analogRead(joystickXPin);
  int y = analogRead(joystickYPin);

  // Read the state of each button and joystick axis
  // If a button is pressed, set the corresponding bit in the I2C message to 1
  if (digitalRead(buttonAPin) == LOW){
    i2cMessage |= (1 << buttonABit);
    //Serial.println("Button A pressed");
  }

  if (digitalRead(buttonBPin) == LOW){
    i2cMessage |= (1 << buttonBBit);
    //Serial.println("Button B pressed");
  }

  if (digitalRead(selectButtonPin) == LOW){
    i2cMessage |= (1 << selectButtonBit);
    //Serial.println("Select button pressed");
  }

  if (digitalRead(startButtonPin) == LOW){
    i2cMessage |= (1 << startButtonBit);
    //Serial.println("Start button pressed");
  }

  // if (y > UPPER){
  //   i2cMessage |= (1 << upButtonBit);
  //   //Serial.println("Up button pressed");
  // }
  // else if (y < LOWER){
  //   i2cMessage |= (1 << downButtonBit);
  //   //Serial.println("down button pressed");
  // }

  // if (x > UPPER){
  //   i2cMessage |= (1 << leftButtonBit);
  //   //Serial.println("left button pressed");
  // }
  // else if (x < LOWER){
  //   i2cMessage |= (1 << rightButtonBit);
  //   //Serial.println("right button pressed");
  // }

  // //write controller input byte (like NES) over I2C
  Serial.println(i2cMessage);
  Wire.beginTransmission(1);
  Wire.write(i2cMessage);             
  Wire.endTransmission();    

}