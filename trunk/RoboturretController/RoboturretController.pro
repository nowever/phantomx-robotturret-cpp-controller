#-------------------------------------------------
#
# Project created by QtCreator 2012-05-18T13:48:16
#
#-------------------------------------------------

QT       += core gui

TARGET = RoboturretController
TEMPLATE = app

include(./qextserialport-1.2beta1/src/qextserialport.pri)

SOURCES += main.cpp\
        mainwindow.cpp \
    RobotTurretMessagePort.cpp

HEADERS  += mainwindow.h \
    RobotTurretMessagePort.h

FORMS    += mainwindow.ui


INCLUDEPATH += "E:/PCL 1.5.1/3rdParty/Eigen/include"

# If you don't want log4cxx comment it out in the code
win32:CONFIG(release, debug|release): LIBS += -L"D:/RTA_Project/Tools/log4cxx-0.10.0/projects/release/" -llog4cxx
else:win32:CONFIG(debug, debug|release): LIBS += -L"D:/RTA_Project/Tools/log4cxx-0.10.0/projects/debug/" -llog4cxx

INCLUDEPATH += "D:/RTA_Project/Tools/log4cxx-0.10.0/src/main/include"



















