#include <Wire.h>

// red - ground, black (brown) - 5V
const int PULSE = 4; // yellow
const int LATCH = 2; // green
const int DATA = 3; //white


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

  return data;
}

void setup() {

  Serial.begin(9600);

  pinMode(DATA, INPUT);
  pinMode(LATCH, OUTPUT);
  pinMode(PULSE, OUTPUT);

  delay(3000);

  Wire.begin(); 
}

void loop() {
  
  uint8_t control = readController();

  Serial.println(control, HEX);

  Wire.beginTransmission(1);
  Wire.write(control);             
  Wire.endTransmission();   

}

