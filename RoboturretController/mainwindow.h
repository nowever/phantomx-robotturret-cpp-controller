#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <log4cxx/logger.h>
#include "RobotTurretMessagePort.h"


namespace Ui {
    class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public: // Types
    typedef double RealType;
    typedef RobotTurretMessagePort::TurretPoseType TurretPoseType;

protected: // Class data
    RobotTurretMessagePort *m_turret;               //!< Message port for sending/receiving messages to/from the turret
    bool m_turretExists;                            //!< Keep track of the existance of the thread (for correct deletion)

public: // ...structors
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private slots: // General Slots
    /// Delete the robot turret thread if it exists
    void DeleteRobotTurretThread();

    /// Listen to the poses provided by the RobotTurretMessagePort
    void TurrentPoseListener(const RealType panRadians, const RealType tiltRadians);

    /// Move the robot turret to a pose as held in radians on the GUI
    void MoveRobotTurretToPose();

private slots: // GUI Slots
    void on_Start_pushButton_clicked();
    void on_PanPercentage_horizontalSlider_valueChanged(int value);
    void on_TiltPercentage_verticalSlider_valueChanged(int value);

private:
    Ui::MainWindow *ui;
    static log4cxx::LoggerPtr m_log; //!< The renamed log
};

#endif // MAINWINDOW_H
