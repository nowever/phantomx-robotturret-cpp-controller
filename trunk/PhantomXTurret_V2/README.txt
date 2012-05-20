__ PhantomX Robot Turret Controller __
--------------------

Can be used to control the Trossen Robotics PhantomX RoboTurret. 
http://www.trossenrobotics.com/p/phantomX-robot-turret.aspx
Or more generally to control AX12 dynamixel servos connected to an Arbotix board.

Note: 
1) You will need at least an Arduino board which can talk RS495 and 1 dynamixel servo
2) If you want to modify the Arduino code it wouldn't be hard to get it to work on another Arduino compatible board  
which can (or has a shield to allow it to) talk to Dynamixel servos

--------------------
__ Author __
Gavin Paul
Gavin.Paul@gmail.com
12th April 2012
Update: 18th May 2012 (added the missing strpad.m file)

--------------------
__ Files in Toolbox __

--------------------

Serial to PantomX Protocol Specification.doc
PhantomXSequencePlayer.m
PhantomXMessagePort.m
PhantomXTurretGUI.m
PhantomXTurret.pde
trajectoryData.mat
README.txt

--------------------
__ Instructions __
--------------------
1) Burn the PhantomXTurret.pde to your arbotix board
2) For how to: 
- use the basic controller type "help PhantomXMessagePort" into matlab command line
- write/load/play a sequence of movements type "help PhantomXSequencePlayer" into matlab command line
- use the GUI type "help PhantomXTurretGUI" into matlab command line

Note: a serial port and a message port are different things. The serial port is lower level and only talks serial, 
while the message port understands the hardware and sends/processes control messages to/from the serial port.
