#include "display.h"
#include <QDebug>

Display::Display(QObject *parent) : QObject(parent){}

void Display::onTempReceived(int val){
    qDebug() << "Nhiet do hien tai:" << val << "do C";
}

