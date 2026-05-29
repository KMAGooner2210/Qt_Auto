qt_add_executable(Chap4_4.2 src/main.cpp)


qt_add_qml_module(Chap4_4.2
    URI Chap4_4_2_Module
    VERSION 1.0
    RESOURCE_PREFIX "/"
    QML_FILES qml/Main.qml
    RESOURCES icons/engine_warning.svg
)

target_link_libraries(Chap4_4.2 PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)
