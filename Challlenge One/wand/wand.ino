//This sketch uses the MPU6050 library made by tockn. The MPU6500 used was sort of broken, because its I2C address changes randomly, so some changes have been made to the library to counteract this unwanted behaviour.
//There is also a small change made to the getAngleZ calculation, because it drifted alot.



#include <MPU6050_tockn.h>
#include <Wire.h>

MPU6050 mpu6050(Wire);

int rawData[3]; //Variable to store the accelerometer data


void setup() {
  Serial.begin(115200);
  Wire.begin();
  mpu6050.begin();
  mpu6050.calcGyroOffsets(true);
}

void loop() {
  mpu6050.update();
  int x = map(mpu6050.getAngleZ(), -200, 200, 0, 1023); //map the variable to the same range as the other values
  int accX = map(mpu6050.getAccX() * 100, -100, 100, 0, 1023); //map the variable to the same range as the other values, first multiply by hundred because the first range is very low and misses a lot of information when mapped
  int accZ = map(mpu6050.getAccZ() * 100, -100, 100, 0, 1023); //map the variable to the same range as the other values, first multiply by hundred because the first range is very low and misses a lot of information when mapped
  int accY = map(mpu6050.getAccY() * 100, -100, 100, 0, 1023); //map the variable to the same range as the other values, first multiply by hundred because the first range is very low and misses a lot of information when mapped

  //prevent a little jumpiness, because the sensor is mounted at the end of the stick is moves a little when trying to hold it still
  if (abs(accX - rawData[0]) > 3) {
    rawData[0] = accX;
  }
  if (abs(accY - rawData[1]) > 3) {
    rawData[1] = accY;
  }
  if (abs(accZ - rawData[2]) > 3) {
    rawData[2] = accZ;
  }

  //Send the data
  Serial.println("X" + String(rawData[0])); //for motion
  Serial.println("Y" + String(rawData[1])); //for motion and aiming
  Serial.println("Z" + String(rawData[2])); //for motion
  Serial.println("A" + String(x)); //for aiming

}
