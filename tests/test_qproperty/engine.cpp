#include "engine.h"
#include <QDebug>

Engine::Engine(QObject *parent) : QObject(parent), m_rpm(0){}

int Engine::getRpm() const{
	return m_rpm;
}

void Engine::setRpm(int val){
	if(m_rpm == val){
		qDebug() << "Engine: Gia tri RPM trung lap (" << val << "). Bo qua khong phat tin hieu";
		return;
	}

	m_rpm = val;
    qDebug() << "Engine: Cap nhat RPM thuc te =" << m_rpm;
	emit rpmChanged(m_rpm);
}


