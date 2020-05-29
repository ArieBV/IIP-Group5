//acc y and angleZ for aiming
//acc x y z for spells



#include <MPU6050_tockn.h>
#include <Wire.h>

MPU6050 mpu6050(Wire);

int rawData[3];


void setup() {
  Serial.begin(115200);
  Wire.begin();
  mpu6050.begin();
  mpu6050.calcGyroOffsets(true);
}

void loop() {
  mpu6050.update();
    int x = map(mpu6050.getAngleZ(),-200,200,0,500);
    int accX = map(mpu6050.getAccX()*100,-100,100,0,500);
    int accZ = map(mpu6050.getAccZ()*100,-100,100,0,500);
    int accY = map(mpu6050.getAccY()*100,-100,100,0,500);
    if(abs(accX - rawData[0]) > 3){
      rawData[0] = accX;
    }
        if(abs(accY - rawData[1]) > 3){
      rawData[1] = accY;
    }
        if(abs(accZ- rawData[2]) > 3){
      rawData[2] = accZ;
    }
    Serial.println("X"+String(rawData[0]));
    Serial.println("Y"+String(rawData[1]));  //for motion and aiming
    Serial.println("Z"+String(rawData[2]));
    Serial.println("A"+String(x));  //for aiming
//    Serial.println("Z"+String(0));  //for aiming
    
}
