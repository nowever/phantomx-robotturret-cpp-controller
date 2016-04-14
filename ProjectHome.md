I wanted a C++ controller with a GUI and I couldn't build the ones available. This is a simple GUI and controller written in C++ using QT libraries.

I use the QTextserialport library which is a small but very useful serial port library written in C++/QT, which I have included in the project.

I designed a simple serial protocol, and coded a Arduino server for the ArbotiX board to talk in this protocol to the computer controller.

I also wrote a Matlab controller which speaks the same protocol and is available here:

http://www.mathworks.com/matlabcentral/fileexchange/36147-phantomx-robot-turret-controller


Extract about the RobotTurret from the Trossen Robotics webpage: http://www.trossenrobotics.com/p/phantomX-robot-turret.aspx

The PhantomX Robot Turret is a high performance Pan & Tilt platform for experimenters, roboticists, and hobbyists, making it easy to get started in the exciting field of physical computing! This easy to build kit is based around the exclusive ArbotiX Robocontroller and AX-12 Dynamixel Actuators.