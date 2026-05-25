#ifndef SENSOR_H
#define SENSOR_H

#include <QObject>

class Sensor : public QObject {
	Q_OBJECT
public:
	explicit Sensor(QObject *parent = nullptr);
	void updateTemperature(int newTemp);

signals:
	void tempChanged(int val);
};

#endif
