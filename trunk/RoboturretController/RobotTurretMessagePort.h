
#ifndef ROBOTTURRETMESSAGEPORT_H_
#define ROBOTTURRETMESSAGEPORT_H_

#include <QThread>
#include <QList>
#include <log4cxx/logger.h>
#include "qextserialport.h"
#include <Eigen/Dense>

class RobotTurretMessagePort : public QThread
{
Q_OBJECT

public: // Types
    typedef double RealType;
    typedef Eigen::Vector2d TurretPoseType;
    typedef QList<TurretPoseType> TurretTrajectoryType;

public: // Constants
    const static int PACKET_LENGTH = 12;            //!< The length in bytes of a single message packet (commanding both joints)
    const static int MIN_PAN_STEP = 0;              //!< The physical step limit (topdown clockwise direction)
    const static int MAX_PAN_STEP = 1027;           //!< The physical step limit (topdown anti-clockwise direction)
    const static int MIN_TILT_STEP = 160;           //!< The physical step limit (from right hand side clockwise direction)
    const static int MAX_TILT_STEP = 850;           //!< The physical step limit (from right hand side anti-clockwise direction)
    const static int ZERO_RADIANS_PAN_STEP = 513;   //!< The starting pan pose step
    const static int ZERO_RADIANS_TILT_STEP = 513;  //!< The starting tilt pose step
    const static int STEPS_PER_RADIAN = 196;        //!< Number of steps in each radian calculated by: 1024steps / deg2rad(300degs)
    const static int AX12_STEP_LIMIT = 1024;        //!< The actual physical step limit of the dynamixel AX12 servos

protected: // Class data
    QextSerialPort *m_port;                         //!< Serial port for communications
    QString m_portName;                             //!< Serial port name (on my windows machine COM14)
    bool m_stopFlag;                                //!< State of the thread (is stopped) or not
    TurretPoseType m_pose;                          //!< Value in radians of the last report pose (pan, tilt) radians

public: // ...structors    
    RobotTurretMessagePort(QObject *parent, const QString & portName);
    EIGEN_MAKE_ALIGNED_OPERATOR_NEW                 //!< Required by Eigen

public: // Methods
    /// Pad a string with some characters
    QString strpad(QString str,int requiredLength,bool preNotPost, QString paddingChar );

public slots:
    /// Stop the thread
    void StopThread();

    /// Send command to move to a pose
    void MoveToPose(RealType pan,RealType tilt);

signals:
    void TurrentPoseProvider(const RealType &,const RealType &);

private slots:
    /// Callback called when there is data to read from the serial read buffer
    void onReadyRead();

    /// When the DSR state is changed this callback is called
    void onDsrChanged(bool status);

private: // Class methods
    /// Thread start method
    void run();

private: // Class data
    static log4cxx::LoggerPtr m_log; //!< The renamed log
};


#endif // ROBOTTURRETMESSAGEPORT_H_
