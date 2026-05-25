#include <QCoreApplication>
#include <QDebug>
#include "node.h"

int main(int argc, char *argv[]){
	QCoreApplication a(argc, argv);
	qDebug() << "=== START MEMORY LEAK TEST ===";
	
	Node * parentNode = new Node();
	
	Node * child1 = new Node(parentNode);
	Node * child2 = new Node(parentNode);
	Node * child3 = new Node(parentNode);

	qDebug() << "-------------";
	qDebug() << "Deleting parent now...";

	delete parentNode;
	qDebug() << "END OF TEST";
	return 0;
}
