#include "node.h"

Node::Node(QObject *parent) : QObject(parent){
	qDebug() << "Created node:" << this;
}

Node::~Node(){
	qDebug() << "Deleted node:" << this;
}

