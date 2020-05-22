#include <Adafruit_CircuitPlayground.h>
#include <Adafruit_Circuit_Playground.h>

//*********************************************
// Time-Series Signal Processing
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************


int sampleRate = 100; //samples per second
int sampleInterval = 1000000/sampleRate; //Inverse of SampleRate
int data = 0;
long timer = micros(); //timer

void setup() {
  Serial.begin(115200); //serial
  CircuitPlayground.begin();
  CircuitPlayground.setAccelRange(LIS3DH_RANGE_8_G);
}

void loop() {
  if (micros() - timer >= sampleInterval) { //Timer: send sensor data in every 10ms
    timer = micros();
    //data = analogRead(A8); //get the analog reading
    data = CircuitPlayground.motionX();
    Serial.println(data);
  }
}
