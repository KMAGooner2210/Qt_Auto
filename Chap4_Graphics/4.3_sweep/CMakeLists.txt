qt_add_executable(Chap4_4.3 src/main.cpp)

qt_add_qml_module(Chap4_4.3
	URI Chap4_4_3_Module
	VERSION 1.0
	RESOURCE_PREFIX "/"
	QML_FILES
		qml/Main.qml
		qml/GaugeRing.qml
	RESOURCES
		icons/needle.svg
)

target_link_libraries(Chap4_4.3 PRIVATE
	Qt6::Core
	Qt6::Gui
	Qt6::Qml
	Qt6::Quick
)
