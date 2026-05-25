#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

int main(int argc, char *argv[]){
	QGuiApplication app(argc, argv);
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [](){
        qDebug() << "================";
        qDebug() << "System is shutting down...Saving logs...";
        qDebug() << "Closing CAN sockets";
        qDebug() << "================";
});

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("ClusterAppModule", "Main");
	return app.exec();
}
				
