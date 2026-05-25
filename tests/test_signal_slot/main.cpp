#include <QCoreApplication>
#include <QDebug>
#include "sensor.h"
#include "display.h"

int main(int argc, char * argv[]){
	QCoreApplication a(argc, argv);
	qDebug() << "=== START SIGNAL & SLOT TEST ===";
	Sensor engineSensor;
	Display cockpitDisplay;
	
	QObject::connect(&engineSensor, &Sensor::tempChanged,
			 &cockpitDisplay, &Display::onTempReceived);
	qDebug() << "Da thiet lap ket noi giua Sensor va Display";
	qDebug() << "----------------------------------------";
	
	engineSensor.updateTemperature(29);
	return 0;
}
