#include "mytcpsocket.h"

MyTcpSocket::MyTcpSocket(QObject *parent) :
    QObject(parent)
{
}

void MyTcpSocket::doConnect()
{
    socket = new QTcpSocket(this);

    connect(socket, SIGNAL(connected()),this, SLOT(connected()));
    connect(socket, SIGNAL(disconnected()),this, SLOT(disconnected()));
    connect(socket, SIGNAL(bytesWritten(qint64)),this, SLOT(bytesWritten(qint64)));
    connect(socket, SIGNAL(readyRead()),this, SLOT(readyRead()));

    qDebug() << (QTime::currentTime().toString("hh:mm:ss.zzzz") + ": Connecting...");

    connect(this, SIGNAL(readAgain()), this, SLOT(connected()));

    // This is not blocking call:
    socket->connectToHost("192.168.11.11", 80);

    // We need to wait...
    if(!socket->waitForConnected(5000))
    {
        qDebug() << "Error: " << socket->errorString();
    }
}

void MyTcpSocket::connected()
{
    //qDebug() << (QTime::currentTime().toString("hh:mm:ss.zzzz") + ": Connected...");
    // Hey server, tell me about you:
    socket->write("FRQ?");
}

void MyTcpSocket::disconnected()
{
    qDebug() << (QTime::currentTime().toString("hh:mm:ss.zzzz") + ": Disconnected...");
}

void MyTcpSocket::bytesWritten(qint64 bytes)
{
    //qDebug() << bytes << " bytes written...";
}

void MyTcpSocket::readyRead()
{
    QByteArray Bytes;

    //qDebug() << (QTime::currentTime().toString("hh:mm:ss.zzzz") + ": reading...");

    // Read the data from the socket
    //qDebug() << socket->readAll();
    Bytes = socket->readAll();
    //qDebug() << Bytes.size() << " bytes read.";
    qDebug() << (QTime::currentTime().toString("hh:mm:ss.zzzz") + ": " +
                QString::number((uint8_t(Bytes[0]) << 24) + (uint8_t(Bytes[1]) << 16) + (uint8_t(Bytes[2]) << 8) + uint8_t(Bytes[3])));

    emit readAgain();
}
