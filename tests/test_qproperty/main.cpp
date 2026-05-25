#include <QCoreApplication>
#include <QDebug>
#include "engine.h"

class DashboardObserver : public QObject {
	Q_OBJECT
public:
    explicit DashboardObserver(QObject *parent = nullptr) : QObject(parent){}
public slots:
	void onRpmChanged(int newRpm){
		qDebug() << "DashboardObserver: [NOTIFY] Kim vong tua quay toi:" << newRpm << "RPM.";
	}
};

int main(int argc, char * argv[]){
	QCoreApplication a(argc, argv);
	Engine carEngine;
	DashboardObserver dashboard;
	
	QObject::connect(&carEngine, &Engine::rpmChanged,
			 &dashboard, &DashboardObserver::onRpmChanged);
	
	qDebug() << "\n--- TEST 1: SET RPM LEN 3000 ---";
	carEngine.setRpm(3000);
	
	qDebug() << "\n--- TEST 2: SET RPM LEN 3000 LAN 2 ---";
	carEngine.setRpm(3000);
	
	qDebug() << "\n--- TEST 3: SET RPM VE 1000 ---";
	carEngine.setRpm(1000);
	
	return 0;
}

#include "main.moc"