#include <ax12.h>
#include <BioloidController.h>

// Hardware Constructs
BioloidController bioloid = BioloidController(1000000);
    
// Defines
#define PAN    1 // Dynamixel servo identifier
#define TILT   2 // Dynamixel servo identifier

#define HEADER 58 // The first byte of a serial packet
#define SEPARATOR 44 // The separator between the pan and tilt values
#define FOOTER 59 // The last byte of a serial packet

#define PAN_ZERO_POSITION 512 // The center of the pan servo motion (the zero degrees position)
#define TILT_ZERO_POSITION 512 // The center of the tilt servo motion (the zero degrees position)

#define PAN_STEP_TOLERANCE 10 // The number of steps tolerance for PAN before stop monitoring (essentially pass-by mode)
#define TILT_STEP_TOLERANCE 10 // The number of steps tolerance for TILT before stop monitoring (essentially pass-by mode)

#define MIN_TILT_STEP 160 // The lowest TILT step value that is allowed (hardware min is 140, DO NOT GO ALL THE WAY TO THIS VALUE!)
#define MAX_TILT_STEP 850 // The lowest TILT step value that is allowed (hardware max is 866, DO NOT GO ALL THE WAY TO THIS VALUE!)
#define MAX_PAN_STEP 1023 // The maximum number of steps the servo can go up to (all of them)
// Global variables
int pan;
int tilt;
unsigned char singleByte;

bool debug = false; // Needs to be off for actual communication with external apps other than the arduino serial monitor

void setup(){
  // setup LED
  pinMode(0,OUTPUT);
  // setup serial
  Serial.begin(38400);
  
  bioloid.poseSize = 2;
  
  // raise turret
  pan = PAN_ZERO_POSITION;
  tilt = TILT_ZERO_POSITION; 
  bioloid.readPose();
  bioloid.setNextPose(PAN,pan);
  bioloid.setNextPose(TILT,tilt);
  bioloid.interpolateSetup(100);
  while(bioloid.interpolating > 0){
    bioloid.interpolateStep();
    delay(1);
  }
}

// Main loop
void loop()
{
  // If there is a valid packet sent :pppp,tttt; then execute the movement
  if (readSerialData())
  {
    // Correct for out of bounds errors
    if (MAX_TILT_STEP < tilt)
      tilt = MAX_TILT_STEP;
    else if (tilt < MIN_TILT_STEP)
      tilt = MIN_TILT_STEP;
    if (MAX_PAN_STEP < pan)
      pan = MAX_PAN_STEP;
    
    // If debugging then  print out pan and tilt values
    if (debug)
    {
      Serial.print("Pan = ");Serial.print(pan);
      Serial.print(", Tilt = ");Serial.println(tilt);      
    }

    //Execute the movement to within the tolerance
    exectureMove();
  }
  
  // Print on serial line the current possition using same protocol :pppp,tttt;
  printCurrentPose();
}

//  Print on serial line the current possition using same protocol :pppp,tttt; 
void printCurrentPose()
{
  // Get the current pose
  bioloid.readPose(); 
  // Print header of packet
  Serial.print(char(HEADER));
  
  // Print PAN data of packet in form 0000 to 1027
  if (bioloid.getCurPose(PAN) < 1000)
    Serial.print("0");
  if (bioloid.getCurPose(PAN) < 100)
    Serial.print("0");    
  if (bioloid.getCurPose(PAN) < 10)
    Serial.print("0");        
  Serial.print(bioloid.getCurPose(PAN));  
  
  // Print separator between pan and tilt values
  Serial.print(char(SEPARATOR));

  // Print TILT data of packet in form 0000 to 1027
  if (bioloid.getCurPose(TILT) < 1000)
    Serial.print("0");
  if (bioloid.getCurPose(TILT) < 100)
    Serial.print("0");    
  if (bioloid.getCurPose(TILT) < 10)
    Serial.print("0");    
  Serial.print(bioloid.getCurPose(TILT));

  // Print footer of packet  
  Serial.println(char(FOOTER));    
}

// Issue a command (called by executeMove)
void issueMoveCommand()
{
  bioloid.setNextPose(PAN,pan);
  bioloid.setNextPose(TILT,tilt);
  bioloid.interpolateSetup(0);
  while(bioloid.interpolating > 0)
    bioloid.interpolateStep();
    
  //printCurrentPose();   
}

// Execture a command to within some desired tolerance
void exectureMove()
{
  // Issue the move command
  issueMoveCommand();
  
  // Read the current pose
  bioloid.readPose(); 
  
  // Read the value of the current pose
  int previousPanPose = bioloid.getCurPose(PAN); 
  int previousTiltPose = bioloid.getCurPose(TILT);
  
  // Wait until within the desired tolerance before returning
  while(PAN_STEP_TOLERANCE < abs(bioloid.getCurPose(PAN)-pan)
     || TILT_STEP_TOLERANCE < abs(bioloid.getCurPose(TILT)-tilt))
  {
    if (debug)
    {
      Serial.print("Waiting since: Pan pose = ");Serial.print(bioloid.getCurPose(PAN));
      Serial.print(" Tilt pose = ");Serial.println(bioloid.getCurPose(TILT));
    }
  
    // Update the previous pose
    previousPanPose = bioloid.getCurPose(PAN);
    previousTiltPose = bioloid.getCurPose(TILT);    
    // Read the current pose
    bioloid.readPose(); 
   
    //printCurrentPose();
    delay(10);    
    //printCurrentPose();

    // Check if moved anywhere between the last read and this read. If not the reissue command
    if (abs(bioloid.getCurPose(PAN)-previousPanPose)==0
     || abs(bioloid.getCurPose(TILT)-previousTiltPose)==0 )
      issueMoveCommand();
  }

  //If debugging print out the values
  if (debug)
  {
    Serial.print("Finished: Pan pose = ");Serial.print(bioloid.getCurPose(PAN));
    Serial.print(" Tilt pose = ");Serial.println(bioloid.getCurPose(TILT));
  }
}

// Read the current serial data
bool readSerialData()
{
  int byteIndex = 0; 
  while(0 < Serial.available()) 
  {
    singleByte = Serial.read();
    if (debug)
    {
      Serial.print("byteIndex: ");
      Serial.print(byteIndex);
      Serial.print(" = ");
      Serial.println(singleByte);
    }
      
    // Depending up which byte index it is a differnt value in the packet is expected  
    switch (byteIndex) 
    {
      case 0:
        if (singleByte != HEADER)
          return false;
        break;
      case 1:
        pan = char2int(singleByte) * 1000;
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;
        break;
      case 2:
        pan += char2int(singleByte) * 100;
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;
        break;
      case 3:
        pan += char2int(singleByte) * 10;
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;        
        break;
      case 4:
        tilt += char2int(singleByte);
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;        
        break;
      case 5:
        if (singleByte != SEPARATOR)
          return false;
        break;
      case 6:
        tilt = char2int(singleByte) * 1000;
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;        
        break;
      case 7:
        tilt += char2int(singleByte) * 100;
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;        
        break;
      case 8:
        tilt += char2int(singleByte) * 10;
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;        
        break;
      case 9:
        tilt += char2int(singleByte);
        // Invalid singleByte has been found so return
        if (char2int(singleByte) < 0) return false;        
        break;        
      case 10:
        if (singleByte != FOOTER)
          return false;
        else
          return true;
      default:
        return false; // 
    }
    byteIndex++;
  }
}

// Change the ascii value to int value to work with
int char2int(unsigned char charValue)
{
  // Only valid values are between 0 and 9 in ascii which has HEX values of 48 to 57 
  if ((48 <= charValue) && (charValue <= 57))
    return int(charValue-48);
  else
    return -1;
}
