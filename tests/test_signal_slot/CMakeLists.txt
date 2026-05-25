qt_add_executable(test_signal_slot
	main.cpp
	sensor.h
	sensor.cpp
	display.h
	display.cpp
)

target_link_libraries(test_signal_slot PRIVATE
	Qt6::Core
)
