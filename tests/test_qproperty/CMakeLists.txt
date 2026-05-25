qt_add_executable(test_qproperty
	main.cpp
	engine.h
	engine.cpp
)

target_link_libraries(test_qproperty PRIVATE
	Qt6::Core
)
