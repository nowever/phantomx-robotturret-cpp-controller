#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <qDebug>

    log4cxx::LoggerPtr
MainWindow::m_log(log4cxx::Logger::getLogger("MainWindow"));

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)   
    , m_turretExists(false)
{
    LOG4CXX_DEBUG(m_log, "MainWindow:");
    ui->setupUi(this);
    qRegisterMetaType<RobotTurretMessagePort::TurretPoseType>("TurretPoseType");

    connect(ui->Stop_pushButton,SIGNAL(clicked()),this,SLOT(DeleteRobotTurretThread()));
}

MainWindow::~MainWindow()
{
    LOG4CXX_DEBUG(m_log, "~MainWindow:");
    DeleteRobotTurretThread();
    LOG4CXX_DEBUG(m_log, "~MainWindow: Delete ui");
    delete ui;
}

    void
MainWindow::on_Start_pushButton_clicked()
{
    LOG4CXX_DEBUG(m_log, "on_Start_pushButton_clicked:");
    ui->Start_pushButton->setEnabled(false);
    ui->Stop_pushButton->setEnabled(true);
    ui->PanPercentage_horizontalSlider->setEnabled(true);
    ui->TiltPercentage_verticalSlider->setEnabled(true);
    ui->PortName_lineEdit->setEnabled(false);

    m_turret = new RobotTurretMessagePort(this,ui->PortName_lineEdit->text());
    m_turret->start();
    m_turretExists = true;

    connect(m_turret,SIGNAL(TurrentPoseProvider(const RealType &,const RealType &))
            ,this,SLOT(TurrentPoseListener(const RealType &,const RealType &)));
}


    void
MainWindow::TurrentPoseListener(RealType panRadians, RealType tiltRadians)
{
    LOG4CXX_DEBUG(m_log, "TurrentPoseListener: "
                  << " panRadians " << panRadians
                  << ", tiltRadians " << tiltRadians);
    ui->ActualPanPoseValue_label->setText(QString::number(panRadians));
    ui->ActualTiltPoseValue_label->setText(QString::number(tiltRadians));
}

    void
MainWindow::DeleteRobotTurretThread()
{
    LOG4CXX_DEBUG(m_log, "DeleteRobotTurretThread:");
    ui->Start_pushButton->setEnabled(true);
    ui->Stop_pushButton->setEnabled(false);
    ui->PanPercentage_horizontalSlider->setEnabled(false);
    ui->TiltPercentage_verticalSlider->setEnabled(false);
    ui->PortName_lineEdit->setEnabled(true);

    if (m_turretExists)
    {
        m_turret->StopThread();
        m_turret->wait(500);
        m_turret->deleteLater();
        m_turretExists = false;
    }    
}

    void
MainWindow::MoveRobotTurretToPose()
{
    LOG4CXX_DEBUG(m_log, "MoveRobotTurretToPose:");
    if (!m_turretExists)
    {
        LOG4CXX_ERROR(m_log, "MoveRobotTurretToPose: !m_turretExists");
        return;
    }

    TurretPoseType pose;
    pose(0) = ui->DesiredPanPoseValue_label->text().toDouble();
    pose(1) = ui->DesiredTiltPoseValue_label->text().toDouble();
    m_turret->MoveToPose(pose(0), pose(1));
}

    void
MainWindow::on_TiltPercentage_verticalSlider_valueChanged(int value)
{
    LOG4CXX_DEBUG(m_log, "on_TiltPercentage_verticalSlider_valueChanged: percentage" << value);

    RealType radians = RealType(value-50)/100.0                                     // Percentage in 0-1 range
                     * RealType(m_turret->MAX_TILT_STEP - m_turret->MIN_TILT_STEP)  // Full range of steps
                     / RealType(m_turret->STEPS_PER_RADIAN);                        // Number of steps in each radian
    LOG4CXX_DEBUG(m_log, "on_TiltPercentage_verticalSlider_valueChanged: radians" << radians);
    ui->DesiredTiltPoseValue_label->setText(QString::number(radians));
    emit MoveRobotTurretToPose();
}

    void
MainWindow::on_PanPercentage_horizontalSlider_valueChanged(int value)
{
    LOG4CXX_DEBUG(m_log, "on_PanPercentage_horizontalSlider_valueChanged: percentage" << value);

    RealType radians = RealType(value-50)/100.0                                     // Percentage in 0-1 range
                     * RealType(m_turret->MAX_PAN_STEP - m_turret->MIN_PAN_STEP)    // Full range of steps
                     / RealType(m_turret->STEPS_PER_RADIAN);                        // Number of steps in each radian
    LOG4CXX_DEBUG(m_log, "on_PanPercentage_horizontalSlider_valueChanged: radians" << radians);
    ui->DesiredPanPoseValue_label->setText(QString::number(radians));
    emit MoveRobotTurretToPose();
}



/// NOTE: KEEP THESE COMMENTED OUT FOR NOW
//void MainWindow::on_TiltRadians_doubleSpinBox_valueChanged(double arg1)
//{
//    LOG4CXX_DEBUG(m_log, "on_TiltRadians_doubleSpinBox_valueChanged: arg1" << arg1);
//    int percentage = int(arg1 * RealType(m_turret->STEPS_PER_RADIAN)/1028.0 * 100) + 50;
//    LOG4CXX_DEBUG(m_log, "on_TiltRadians_doubleSpinBox_valueChanged: percentage" << percentage);
//    ui->TiltPercentage_verticalSlider->setValue(percentage);
//}

//void MainWindow::on_PanRadians_doubleSpinBox_valueChanged(double arg1)
//{
//    LOG4CXX_DEBUG(m_log, "on_PanRadians_doubleSpinBox_valueChanged: arg1" << arg1);
//    int percentage = int(arg1 * RealType(m_turret->STEPS_PER_RADIAN)/1028.0 * 100) + 50;
//    LOG4CXX_DEBUG(m_log, "on_PanRadians_doubleSpinBox_valueChanged: percentage" << percentage);
//    ui->PanPercentage_horizontalSlider->setValue(percentage);
//}
/// END -- KEEP THESE COMMENTED OUT FOR NOW
