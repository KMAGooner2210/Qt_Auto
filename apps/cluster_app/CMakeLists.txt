qt_add_executable(cluster_app src/main.cpp)

qt_add_qml_module(cluster_app
	URI ClusterAppModule
	VERSION 1.0
	QML_FILES qml/Main.qml
)


target_link_libraries(cluster_app PRIVATE
	Qt6::Core
	Qt6::Gui
	Qt6::Qml
	Qt6::Quick
)


