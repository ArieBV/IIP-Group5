//*********************************************
// Example Code for Interactive Intelligent Products
// Rong-Hao Liang: r.liang@tue.nl

//The example code from Rong-Hao Liang was used to make our own code, which can determine different kinds of spells based on motion, and aim those spells at targets
//*********************************************



import processing.sound.*;
SqrOsc square;


import papaya.*;
import processing.serial.*;
Serial port; 

int sensorNum = 4; 
int streamSize = 500;
int[] rawData = new int[sensorNum];
float[][] sensorHist = new float[sensorNum][streamSize]; //history data to show

float[][] diffArray = new float[sensorNum][streamSize]; //diff calculation: substract

float[] modeArray = new float[streamSize]; //To show activated or not
float[][] thldArray = new float[sensorNum][streamSize]; //diff calculation: substract
int activationThld = 80; //The diff threshold of activiation

int windowSize = 200; //The size of data window
float[][] windowArray = new float[sensorNum][windowSize]; //data window collection
boolean b_sampling = false; //flag to keep data collection non-preemptive
int sampleCnt = 0; //counter of samples

//Save
Table csvData;
boolean b_saveCSV = false;
String dataSetName = "A0GestTest"; 
String[] attrNames = new String[]{"m_x", "sd_x", "label"};
boolean[] attrIsNominal = new boolean[]{false, false, true};
int labelIndex = 0;

float m_x = -1;
float sd_x = -1;
float m_y = -1;
float sd_y = -1;
float m_z = -1;
float sd_z = -1;
boolean bShowInfo = true;

String prediction;
int spellTime;    //Time before spell effect wears off

float[] prevX = {0, 0, 0, 0, 0, 0}; //Variable to store the previous data (m_x,sd_x etc)
boolean showSpell = false;

boolean dataUpdated = false;

void setup() {
  size(1920, 1080, P2D);
  initSerial();
  loadTrainARFF(dataset="A012GestTest.arff"); //load a ARFF dataset
  trainLinearSVC(C=64);             //train a SV classifier
  setModelDrawing(unit=2);         //set the model visualization (for 2D features)
  evaluateTrainSet(fold=5, isRegression=false, showEvalDetails=true);  //5-fold cross validation
  saveModel(model="LinearSVC.model"); //save the model

  square = new SqrOsc(this);
}

void draw() {
  background(51);
  fill(255);
  float[] X = {m_x, sd_x, m_y, sd_y, m_z, sd_z}; 
  prediction = getPrediction(X);
  
  //If the previous prediction data is not the same as the current, start the spell
  if (X[0] != prevX[0]) {
    prevX = X;
    showSpell = true;
    spellTime = 80;
  } else {
    square.stop();
  }
  if (showSpell) {
    spellTime--;  //Decrese the counter for the spell


//Play different sounds and show different color based on the prediction
    if (prediction.equals("A")) {
      fill(255, 0, 0);
      square.play();
      square.freq(200);
    } else if (prediction.equals("B")) {
      fill(0, 255, 0);
      square.play();
      square.freq(400);
    } else if (prediction.equals("C")) {
      fill(0, 0, 255);
      square.play();
      square.freq(600);
    } else if (prediction.equals("D")) {
      fill(255, 255, 0);
      square.play();
      square.freq(800);
    }
    if (spellTime <= 0) {
      showSpell = false;
    }
  }


//Map the angle Z and acc Y to x and y coordinates on the screen, the second range is bigger than the actual screen so aiming is faster
  float Xas = map(rawData[3], 0, height, -1000, 3000); 
  float Yas = map(rawData[1], height, 0, -1000, 2000);
  
  //Show where you are aiming
  ellipse(Xas, Yas, 60, 60);
  
  
  // Place four targets
  fill(2550, 0, 0);
  ellipse(650, 200, 150, 150);
  fill(0, 255, 0);
  ellipse(1300, 200, 150, 150);
  fill(0, 0, 255);
  ellipse(650, 700, 150, 150);
  fill(255, 255, 0);
  ellipse(1300, 700, 150, 150);
}

void keyPressed() {
  if (key == 'A' || key == 'a') {
    activationThld = min(activationThld+5, 100);
  }
  if (key == 'Z' || key == 'z') {
    activationThld = max(activationThld-5, 10);
  }
  if (key == 'I' || key == 'i') {
    bShowInfo = (bShowInfo? false:true);
  }
}

float diff = 0;
void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  if (inData.charAt(0) == 'X') {
    rawData[0] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[0]), map(rawData[0], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[0])[0] - (sensorHist[0])[1]), diff); //absolute diff
    appendArray(diffArray[0], diff);
    appendArray(thldArray[0], activationThld);
  }
  if (inData.charAt(0) == 'Y') {
    rawData[1] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[1]), map(rawData[1], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[1])[0] - (sensorHist[1])[1]), diff); //absolute diff
    appendArray(diffArray[1], diff);
    appendArray(thldArray[1], activationThld);
  }
  if (inData.charAt(0) == 'A') {
    rawData[3] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[3]), map(rawData[3], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[3])[0] - (sensorHist[3])[1]), diff); //absolute diff
    appendArray(diffArray[3], diff);
    appendArray(thldArray[3], activationThld);
  }
  if (inData.charAt(0) == 'Z') {
    rawData[2] = int(trim(inData.substring(1)));
    appendArray( (sensorHist[2]), map(rawData[2], 0, 1023, 0, height)); //store the data to history (for visualization)
    //calculating diff
    diff = max(abs( (sensorHist[2])[0] - (sensorHist[2])[1]), diff); //absolute diff
    appendArray(diffArray[2], diff);
    appendArray(thldArray[2], activationThld);

    //test activation threshold
    if (diff>activationThld) { 
      appendArray(modeArray, 2); //activate when the absolute diff is beyond the activationThld
      if (b_sampling == false) { //if not sampling
        b_sampling = true; //do sampling
        sampleCnt = 0; //reset the counter
        for (int i = 0; i < sensorNum; i++) {
          for (int j = 0; j < windowSize; j++) {
            (windowArray[i])[j] = 0; //reset the window
          }
        }
      }
    } else { 
      if (b_sampling == true) appendArray(modeArray, 3); //otherwise, deactivate.
      else appendArray(modeArray, -1); //otherwise, deactivate.
    }
    diff = 0;
    if (b_sampling == true) {
      for ( int c = 0; c < sensorNum; c++) {
        appendArray(windowArray[c], rawData[c]); //store the windowed data to history (for visualization)
      }
      ++sampleCnt;
      if (sampleCnt == windowSize) {
        m_x = Descriptive.mean(windowArray[0]); //mean
        sd_x = Descriptive.std(windowArray[0], true); //standard deviation
        m_y = Descriptive.mean(windowArray[1]); //mean
        sd_y = Descriptive.std(windowArray[1], true); //standard deviation
        m_z = Descriptive.mean(windowArray[2]); //mean
        sd_z = Descriptive.std(windowArray[2], true); //standard deviation
        b_sampling = false; //stop sampling if the counter is equal to the window size
      }
    }
  }
  return;
}

//Append a value to a float[] array.
float[] appendArray (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, tempArray, tempArray.length);
  array[0] = _val;
  arrayCopy(tempArray, 0, array, 1, tempArray.length);
  return array;
}

void initSerial() {
  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[0];//MAC: check the printed list
  //String portName = Serial.list()[9];//WINDOWS: check the printed list
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer
}