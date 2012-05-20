
#include "RobotTurretMessagePort.h"
#include <QtDebug>
#include <QStringRef>
#include <QStringList>

    log4cxx::LoggerPtr
RobotTurretMessagePort::m_log(log4cxx::Logger::getLogger("RobotTurretMessagePort"));

RobotTurretMessagePort::RobotTurretMessagePort(QObject *parent, const QString & portName)
    : QThread(parent)
    , m_portName(portName)
    , m_stopFlag(false)
{
    LOG4CXX_DEBUG(m_log, "RobotTurretMessagePort:");

    this->m_port = new QextSerialPort(m_portName, QextSerialPort::EventDriven);
    m_port->setBaudRate(BAUD38400);
    m_port->setFlowControl(FLOW_OFF);
    m_port->setParity(PAR_NONE);
    m_port->setDataBits(DATA_8);
    m_port->setStopBits(STOP_2);

    if (m_port->open(QIODevice::ReadWrite) == true)
    {
        if (!(m_port->lineStatus() & LS_DSR))
        {
            LOG4CXX_DEBUG(m_log, "run: warning: device is not turned on");
            qDebug() << "warning: device is not turned on";
        }
        LOG4CXX_DEBUG(m_log, "run: listening for data on " << m_port->portName().toStdString());
        qDebug() << "listening for data on" << m_port->portName();
    }
    else
    {
        LOG4CXX_DEBUG(m_log, "run: device failed to open:" << m_port->errorString().toStdString());
        qDebug() << "device failed to open:" << m_port->errorString();
    }
}

// Stop the thread as soon as possible by setting m_stopFlag
    void
RobotTurretMessagePort::StopThread()
{
    LOG4CXX_DEBUG(m_log, "StopThread: ");
    m_stopFlag = true;
}

// Make the thread a runnable task (call Start on the pointer to return immediataly)
    void
RobotTurretMessagePort::run()
{
    LOG4CXX_DEBUG(m_log, "run:");
    m_stopFlag = false;

    connect(m_port, SIGNAL(readyRead()), SLOT(onReadyRead()));
    connect(m_port, SIGNAL(dsrChanged(bool)),SLOT(onDsrChanged(bool)));

    while (!m_stopFlag)
        this->msleep(10);

    m_port->close();
    exit();
}

// Callback when data is available on serial port
    void
RobotTurretMessagePort::onReadyRead()
{
    LOG4CXX_DEBUG(m_log, "onReadyRead:");
    QByteArray bytes;


    int a = m_port->bytesAvailable();
    if (a < PACKET_LENGTH)
        return;

    bytes.resize(a);
    m_port->read(bytes.data(), bytes.size());

    LOG4CXX_DEBUG(m_log, "onReadyRead: Valid packet(s) recieved, processing last " << QString(bytes).toStdString() );
    QStringList allPackets = QString(bytes).split("\n");
    QString latestPacket;

    for (int i = allPackets.length(); 0 < i; --i)
    {
        if (allPackets.at(i-1).size() == PACKET_LENGTH)
        {
            latestPacket = allPackets.at(i-1);
            LOG4CXX_DEBUG(m_log, "onReadyRead: valid packet found at i-1 = " << i-1 << " packet is " << latestPacket.toStdString());
            break;
        }
        else
        {
            LOG4CXX_WARN(m_log, "onReadyRead: invalid allPackets.at("<<i-1<<")" << allPackets.at(i-1).toStdString());
        }

    }
    if (latestPacket.isEmpty())
    {
        LOG4CXX_WARN(m_log, "onReadyRead: No valid packet found");
        return;
    }

    // Extract the approx step count of a pose (byte index is pan = 1:4 & for tilt = 6:10)
    int panSteps =  latestPacket.mid(1,4).toInt();
    int tiltSteps =  latestPacket.mid(6,4).toInt();

    if (panSteps < 0 || tiltSteps < 0 || AX12_STEP_LIMIT < panSteps || AX12_STEP_LIMIT < tiltSteps)
    {
        LOG4CXX_WARN(m_log, "onReadyRead: Out of range pan or tilt receveied. "
                     << " [pan, tilt] steps = [" << panSteps << "," << tiltSteps << "]" );
        return;
    }


    LOG4CXX_DEBUG(m_log, "onReadyRead: [ panSteps " << panSteps << "," << tiltSteps << " tiltSteps ]");

    m_pose(0) = RealType(panSteps - ZERO_RADIANS_PAN_STEP) / STEPS_PER_RADIAN;
    m_pose(1) = RealType(tiltSteps - ZERO_RADIANS_TILT_STEP) / STEPS_PER_RADIAN;
    LOG4CXX_DEBUG(m_log, "onReadyRead: m_pose is set [" << m_pose.transpose() << "] radians");
    //emit TurrentPoseProvider(m_pose);
    emit TurrentPoseProvider(m_pose(0),m_pose(1));
}

// Callback when DSR state changes
    void
RobotTurretMessagePort::onDsrChanged(bool status)
{
    LOG4CXX_DEBUG(m_log, "onDsrChanged:");
    if (status)
    {
        LOG4CXX_DEBUG(m_log, "onDsrChanged: device was turned on");
        qDebug() << "device was turned on";
    }
    else
    {
        LOG4CXX_WARN(m_log, "onDsrChanged: device was turned off");
        qDebug() << "device was turned off";
    }
}

// Convience method for padding a string
    QString
RobotTurretMessagePort::strpad(QString str,int requiredLength,bool preNotPost, QString paddingChar )
{
    LOG4CXX_DEBUG(m_log, "strpad: str " << str.toStdString()
                  << " requiredLength " << requiredLength
                  << " preNotPost " << preNotPost
                  << " paddingChar " << paddingChar.toStdString());

    QString paddedStr = str;

    // Catch invalid cases
    if (1 < paddingChar.size() || requiredLength <= str.size())
    {
        LOG4CXX_ERROR(m_log, "strpad: Invalid. paddingChar.size = " << paddingChar.size()
                      << "requiredLength <= str.size() " << (requiredLength <= str.size()));
        return paddedStr;
    }

    while(paddedStr.size() < requiredLength)
    {
        if (preNotPost)
            paddedStr = paddingChar + paddedStr;
        else
            paddedStr = paddedStr + paddingChar;
    }
    LOG4CXX_DEBUG(m_log, "strpad: " << paddedStr.toStdString());
}

// Move to a pose specified by pan radians and tilt radians
    void
RobotTurretMessagePort::MoveToPose(RealType pan,RealType tilt)
{
    LOG4CXX_DEBUG(m_log, "MoveToPose: [" << pan <<  "," << tilt << "] rads");

    // Extract the approx step count of a pose
    int panSteps = int ( pan * STEPS_PER_RADIAN ) + ZERO_RADIANS_PAN_STEP;
    int tiltSteps = int ( tilt * STEPS_PER_RADIAN ) + ZERO_RADIANS_TILT_STEP;
    LOG4CXX_DEBUG(m_log, "MoveToPose: [" << panSteps <<  "," << tiltSteps << "] steps");
    if (panSteps < MIN_PAN_STEP) panSteps = MIN_PAN_STEP;
    if (MAX_PAN_STEP < panSteps) panSteps = MAX_PAN_STEP;

    if (tiltSteps < MIN_TILT_STEP) tiltSteps = MIN_TILT_STEP;
    if (MAX_TILT_STEP < tiltSteps) tiltSteps = MAX_TILT_STEP;

    // Pad with zeros
    QString pppp = strpad(QString::number(panSteps),4,true,QString("0"));
    QString tttt = strpad(QString::number(tiltSteps),4,true,QString("0"));
    LOG4CXX_DEBUG(m_log, "MoveToPose: padded strings " << pppp.toStdString() <<  " and " << tttt.toStdString());

    // Construct command
    QString cmd = QString(":") + pppp + QString(",") + tttt + QString(";");
    LOG4CXX_DEBUG(m_log, "MoveToPose: command to send " << cmd.toStdString());

    // Send command
    if (m_port->isOpen())
        m_port->write(cmd.toStdString().c_str(),PACKET_LENGTH);
}
