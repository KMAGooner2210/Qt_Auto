cmake_minimum_required(VERSION 3.16)
project(AutomotiveCockpitWorkspace VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

#1. Tim QT6 mot lan duy nhat cho toan bo he thong

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

#2. Add thu muc chua cac thu vien dung chung

# add_subdirectory(shared/assets)
# add_subdirectory(shared/qml_controls)
# add_subdirectory(libs/vehicle_data_model)
# add_subdirectory(libs/can_hardware_service)

#3. Add thu muc chua cac ung dung chinh

#add_subdirectory(apps/cluster_app)
#add_subdirectory(tests/test_memory_leak)
#add_subdirectory(tests/test_signal_slot)
#add_subdirectory(tests/test_qproperty)
#add_subdirectory(apps/ivi_app)
#add_subdirectory(apps/wayland_compositor)
add_subdirectory(Chap3_qml_basics)

