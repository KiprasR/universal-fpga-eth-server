#include <QCoreApplication>
#include <QElapsedTimer>
#include <QStringList>
#include <QTcpSocket>
#include <QString>
#include <QTime>

#include <math.h>
#include <windows.h>

#include "mytcpsocket.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    MyTcpSocket s;
    s.doConnect();

    return a.exec();
}

