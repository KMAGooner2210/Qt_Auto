qt_add_executable(Chap3_3.1 src/main.cpp)

qt_add_qml_module(Chap3_3.1
	URI Chap3_3_1_Module
	VERSION 1.0
	RESOURCE_PREFIX "/"
	QML_FILES qml/Main.qml
)

target_link_libraries(Chap3_3.1 PRIVATE
	Qt6::Core
	Qt6::Gui
	Qt6::Qml
	Qt6::Quick
)
