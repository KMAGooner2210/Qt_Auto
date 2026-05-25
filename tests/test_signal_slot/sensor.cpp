#include "sensor.h"
#include <QDebug>

Sensor::Sensor(QObject *parent) : QObject(parent){}

void Sensor::updateTemperature(int newTemp){
	qDebug() << "Sensor: Doc duoc nhiet do moi =" << newTemp << "do C";
	emit tempChanged(newTemp);
}
