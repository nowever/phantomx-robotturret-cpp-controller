#include <QtGui/QApplication>
#include "mainwindow.h"
#include <log4cxx/propertyconfigurator.h>
#include <log4cxx/logger.h>
#include <QDebug>

int main(int argc, char *argv[])
{
    QString qbuff(argv[0]);
    qbuff.chop(4); // Chop off the ".exe" from the string
    QString filename(qbuff + "." + "properties");
    log4cxx::PropertyConfigurator::configure(log4cxx::File(filename.toStdString()));

    QApplication a(argc, argv);
    MainWindow w;
    w.show();

    return a.exec();
}
