//*********************************************
// Example Code for Interactive Intelligent Products
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************

import processing.serial.*;
Serial port; 

int sensorNum = 3;
int[] rawData = new int[sensorNum];
boolean dataUpdated = false;
float Xas, Yas;

void setup() {
  size(500, 500);             //set a canvas

  //Initialize the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//MAC: check the printed list
  //String portName = Serial.list()[9];//WINDOWS: check the printed list
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer

  loadTrainARFF(dataset="accData_X.arff"); //load a ARFF dataset
  trainLinearRegression();               //train a regressor
  saveModel(model="postureLReg_X.model"); //save the model
  //loadTrainARFF(dataset="accData_Y.arff"); //load a ARFF dataset
  //trainLinearRegression();               //train a regressor
  //saveModel(model="postureLReg_Y.model"); //save the model
  background(52);
}

void draw() {
  if (dataUpdated) {
    background(52);
    fill(255);
    float[] X = {rawData[0], rawData[1], rawData[2]}; 
    double XX = getPredictionIndex(X);
    Xas = 0.9 * Xas + 0.1 * map((float)XX,0,1,0,500);
    Yas = 0.9 * Yas + 0.1 * map(rawData[1], -9,9,0,500);
    textSize(32);
    textAlign(CENTER, CENTER);
    String text = "X-as: "+nf(Xas, 0, 0)+
      "\n Y-as: "+Yas+
      "\n X="+rawData[0]+
      "\n Y="+rawData[1]+
      "\n Z="+rawData[2];
    text(text, width/2, height/2);
    if (rawData[0]<0) {
      port.write('a');//+int(map(abs(rawData[0]),0,9,0,255)));
      println('a');
    } if (rawData[0]>0) {
      port.write('b');//+int(map(abs(rawData[0]),0,9,0,255)));
      println('b');
    } if (rawData[1]<0) {
      port.write('c');//+int(map(abs(rawData[1]),0,9,0,255)));
      println('c');
    } if (rawData[1]>0) {
      port.write('d');//+int(map(abs(rawData[1]),0,9,0,255)));
      println('d');
    }
    ellipse(Xas, Yas, 30, 30);
    dataUpdated = false;
  }
}

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  if (!dataUpdated) 
  {
    if (inData.charAt(0) == 'X') {
      rawData[0] = int(trim(inData.substring(1)));
    }
    if (inData.charAt(0) == 'Y') {
      rawData[1] = int(trim(inData.substring(1)));
    }
    if (inData.charAt(0) == 'Z') {
      rawData[2] = int(trim(inData.substring(1)));
      dataUpdated = true;
    }
  }
  return;
}
