qt_add_executable(test_memory_leak
	main.cpp
	node.h
	node.cpp
)

target_link_libraries(test_memory_leak PRIVATE
	Qt6::Core
)
