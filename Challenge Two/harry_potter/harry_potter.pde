//*********************************************
// Example Code for Interactive Intelligent Products
// Rong-Hao Liang: r.liang@tue.nl

//The example code from Rong-Hao Liang was used to make our own code, which can determine different kinds of spells based on motion, and aim those spells at targets
//*********************************************



import processing.sound.*;
import papaya.*;
import processing.serial.*;

//Variables to store the sound files
SoundFile file1;
SoundFile file2;
SoundFile file3;
SoundFile file4;



Serial port; 

int sensorNum = 4; 
int streamSize = 500;
int[] rawData = new int[sensorNum];
float[][] sensorHist = new float[sensorNum][streamSize]; //history data to show

float[][] diffArray = new float[sensorNum][streamSize]; //diff calculation: substract

float[] modeArray = new float[streamSize]; //To show activated or not
float[][] thldArray = new float[sensorNum][streamSize]; //diff calculation: substract
int activationThld = 200; //The diff threshold of activiation

int windowSize = 250; //The size of data window
float[][] windowArray = new float[sensorNum][windowSize]; //data window collection
boolean b_sampling = false; //flag to keep data collection non-preemptive
int sampleCnt = 0; //counter of samples

//Save
Table csvData;
boolean b_saveCSV = false;
String dataSetName = "A012GestTest"; 
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


//Variables to store the current target location and sort of spell
int xTarget = 1;
int yTarget = 1;
int targetDiameter = 200;
String target = "A";
color colour;

//Variables to keep track of game data
int goal = 10;
int targetsHit = 0;
long totalTime = 0;

//Make an variable for the particles
ParticleSystem ps;


void setup() {
  size(1920, 1080, P2D);
  initSerial();
  loadTrainARFF(dataset="A012GestTest.arff"); //load a ARFF dataset
  trainLinearSVC(C=64);             //train a SV classifier
  setModelDrawing(unit=2);         //set the model visualization (for 2D features)
  evaluateTrainSet(fold=5, isRegression=false, showEvalDetails=true);  //5-fold cross validation
  saveModel(model="LinearSVC.model"); //save the model

  
  createCircle();  //Create the variables for the first target
  
  //Load the sound files
  file1 = new SoundFile(this, "sound/Song1.wav");
  file2 = new SoundFile(this, "sound/Song2.wav");
  file3 = new SoundFile(this, "sound/Song3.wav");
  file4 = new SoundFile(this, "sound/Song4.wav");
  
  
  ps = new ParticleSystem();    //Make a new object for the particle system
}


void draw() {
  background(51);
  fill(255);
  stroke(0);
  textSize(26);
  text("Destroy the targets as fast as possible!", 700, 40);
  fill(255, 0, 0);
  text("Circle", 300, 100);
  fill(0, 255, 0);
  text("Vertical", 700, 100);
  fill(0, 0, 255);
  text("Horizontal", 1100, 100);
  fill(255, 255, 0);
  text("V-Shape", 1500, 100);
  fill(255);

  float[] X = {m_x, sd_x, m_y, sd_y, m_z, sd_z}; 
  prediction = getPrediction(X);
  
  //Map the angle Z and acc Y to x and y coordinates on the screen, the second range is bigger than the actual screen so aiming is faster
  float Xas = map(rawData[3], 0, height, -1000, 3000); 
  float Yas = map(rawData[1], height, 0, -1000, 2000);
  //If the previous prediction data is not the same as the current, start the spell
  if (X[0] != prevX[0]) {
    prevX = X;
    showSpell = true;
    spellTime = 80;
  } else {
  }
  if (showSpell) {

  
  
    spellTime--;  //Decrese the counter for the spell
    
    //while the spell is active, check if it hits the target and is the same spell
    targetHit(int(Xas), int(Yas), prediction);


    //show different color based on the prediction
    if (prediction.equals("A")) {
      fill(255, 0, 0);
    } else if (prediction.equals("B")) {
      fill(0, 255, 0);
    } else if (prediction.equals("C")) {
      fill(0, 0, 255);
    } else if (prediction.equals("D")) {
      fill(255, 255, 0);
    }
    else{
      fill(255);
    }
    if (spellTime <= 0) {
      showSpell = false;
    }
  }

  //Show where you are aiming
  ellipse(Xas, Yas, 60, 60);



//If the user has not hit enough targets yet
  if (targetsHit != goal) {
    switch(target) {
    case "A":
      colour = color(255, 0, 0);
      break;
    case "B":
      colour = color(0, 255, 0);
      break;
    case "C":
      colour = color(0, 0, 255);
      break;
    case "D":
      colour = color(255, 255, 0);
      break;
    }
    //Make the target appear
    myCircle(xTarget, yTarget, targetDiameter, colour);
    totalTime = millis();
  } else {
    fill(255, 255, 255);
    textSize(26);
    text("Your Time was: " + totalTime/1000.0, width/2-100, height/2);
  }

  //Execute the run function in the particle system object
  ps.run();
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

//Create the variables for the target
void createCircle() { 
  //Get a random target
  int x = int(random(0, 4));
  switch(x) {
  case 0:
    target = "A";
    break;
  case 1:
    target = "B";
    break;
  case 2:
    target = "C";
    break;
  case 3:
    target = "D";
    break;
  }
  //Get random coordinates
  xTarget = int(random(0+targetDiameter/2, width-targetDiameter/2));  
  yTarget = int(random(200+targetDiameter/2, height-targetDiameter/2));  //Start from 200 so it is not infront of the explanation text
} 


void targetHit(int x, int y, String prediction) {
  
 //Check if the input coordinates is inside the actual target and the spell prediction is the same as the required spell, play a sound corresponding to the spell and set the correct color for the particles
  if (prediction.equals(target) && (x > xTarget-targetDiameter/2 && x < xTarget+targetDiameter/2) && (y > yTarget-targetDiameter/2 && y < yTarget+targetDiameter/2)) {
    targetsHit++;
    switch(prediction) {
    case "A":
      file1.play();
          ps.setColor(color(255,0,0));
      break;
    case "B":
      file2.play();
          ps.setColor(color(0,255,0));

      break;
    case "C":
      file3.play();
          ps.setColor(color(0,0,255));

      break;
    case "D":
      file4.play();
          ps.setColor(color(255,255,0));

      break;
    }
    //Set the particle system to a new location, add 30 particles.
    ps.setPosition(new PVector(xTarget, yTarget));
    for (int i = 0; i < 30; i++) {

      ps.addParticle();
    }
    //Create the new variables for the new target
    createCircle();
  }
}

void myCircle(int x, int y, int d, color c) {
  //Make the target look like a blob kind of figure
  float xx, yy;
  PVector p;
  float r = d * 0.5;
  fill(c);
  beginShape();
  for (float i = 0; i < TAU; i += TAU / 360) {
    xx = x + r * cos(i);
    yy = y + r * sin(i);
    p = res(xx, yy);
    curveVertex(p.x, p.y);
  }
  endShape(CLOSE);
}

PVector res(float x, float y) {
  float scl, ang, off;
  PVector p;
  p = new PVector(x, y);
  scl = 0.0001;
  ang = noise(p.x * scl, p.y * scl, frameCount * 0.001) * 200;
  off = noise(p.x * scl, p.y * scl, frameCount * 0.001) * 50;
  p.x += cos(ang) * off;
  p.y += sin(ang) * off;
  return p;
}



class ParticleSystem {
  //Class that contains the system for the particles
  ArrayList<Particle> particles;
  PVector origin;
  color colour;

  //On initialize, make a new arraylist
  ParticleSystem() {
    particles = new ArrayList<Particle>();
  }
  
  //Set the position for the particle system
  void setPosition(PVector position){
    origin = position.copy();
  }

  //Add a particle in the list, with the color in the constructor so it can't change later
  void addParticle() {
    particles.add(new Particle(origin,this.colour));
  }
  
  //Set the color to send to the particles later
  void setColor(color c){
    this.colour = c;
  }

  //Show all the particles
  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}


// A simple Particle class

class Particle {
  //Particle class with their own variables
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  color colour;
  
  //set the color of the particle, not used because constructor is a safer solution
  void setColor(color c){
    this.colour = c;
  }

  //Set the variables to random generated numbers in a range
  Particle(PVector l,color c) {
    this.colour = c;
    acceleration = new PVector(0, 0.05);
    velocity = new PVector(random(-1, 1), random(-2, 0));
    PVector p = new PVector(random(l.x-60,l.x+60),random(l.y-60,l.y+60)); //Spawn the particles randomly in a circle at the destination of the old target
    position = p;
    lifespan = 255.0;
  }

  void run() {
    update();
    display();
  }

  //Update the particles information
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 1.0;
  }

  //Display the particle
  void display() {
    stroke(this.colour, lifespan);
    fill(this.colour, lifespan);
    ellipse(position.x, position.y, 8, 8);
  }

  //return whether the particle should be removed or not
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
