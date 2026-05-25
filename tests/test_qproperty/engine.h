#ifndef ENGINE_H
#define ENGINE_H

#include <QObject>

class Engine : public QObject {
	Q_OBJECT
	Q_PROPERTY(int rpm READ getRpm WRITE setRpm NOTIFY rpmChanged)

public:

    explicit Engine(QObject *parent = nullptr);
	
	int getRpm() const;
	void setRpm(int val);

signals:

	void rpmChanged(int val);

private:
	int m_rpm;
};

#endif

