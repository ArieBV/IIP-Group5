//*********************************************
// Time-Series Signal Processing
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
#include <Adafruit_CircuitPlayground.h>
#include <Adafruit_Circuit_Playground.h>
#define PIN_NUM 3

int sampleRate = 100; //samples per second
int sampleInterval = 1000000 / sampleRate; //Inverse of SampleRate
int  data[PIN_NUM]; //data array
char dataID[PIN_NUM] = {'X', 'Y', 'Z'}; //data label
int  pinID[PIN_NUM] = {A0, A1, A2}; //corresponding pins
long timer = micros(); //timer

void setup() {
  Serial.begin(115200); //serial
  CircuitPlayground.begin();
  CircuitPlayground.setAccelRange(LIS3DH_RANGE_2_G);
}

void loop() {
  if (micros() - timer >= sampleInterval) { //Timer: send sensor data in every 10ms
    timer = micros();
    getDataFromProcessing(); //Receive before sending out the signals
    Serial.flush(); //Flush the serial buffer
    for (int i = 0 ; i < PIN_NUM ; i++) {
      if (i == 0) {
        data[i] = CircuitPlayground.motionX();
      } if (i == 1) {
        data[i] = CircuitPlayground.motionY();
      } if (i == 2) {
        data[i] = CircuitPlayground.motionZ();
      }
      sendDataToProcessing(dataID[i], data[i]);
    }
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}

void getDataFromProcessing() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    CircuitPlayground.clearPixels();
    if (inChar == 'a') { //when an 'a' charactor is received.
      CircuitPlayground.setPixelColor(6, 0, 255, 0);
      CircuitPlayground.setPixelColor(7, 0, 255, 0);
      CircuitPlayground.setPixelColor(8, 0, 255, 0);
    } if (inChar == 'b') { //when an 'b' charactor is received.
      CircuitPlayground.setPixelColor(1, 0, 255, 0);
      CircuitPlayground.setPixelColor(2, 0, 255, 0);
      CircuitPlayground.setPixelColor(3, 0, 255, 0);
    } if (inChar == 'd') { //when an 'c' charactor is received.
      CircuitPlayground.setPixelColor(4, 0, 255, 0);
      CircuitPlayground.setPixelColor(5, 0, 255, 0);
    }  if (inChar == 'c') { //when an 'd' charactor is received.
      CircuitPlayground.setPixelColor(0, 0, 255, 0);
      CircuitPlayground.setPixelColor(9, 0, 255, 0);
    }
  }
}
