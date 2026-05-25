#ifndef DISPLAY_H
#define DISPLAY_H

#include <QObject>
class Display : public QObject {
	Q_OBJECT
public:
	explicit Display(QObject *parent = nullptr);

public slots:
	void onTempReceived(int val);
};

#endif
