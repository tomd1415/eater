cmake_minimum_required(VERSION 3.12)

# Pull in SDK (must be before project)
include(pico_sdk_import.cmake)

project(transmit C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialize the SDK
pico_sdk_init()

add_executable(transmit
	transmit.c
        )

pico_enable_stdio_usb(transmit 1)
pico_enable_stdio_uart(transmit 1)

# create map/bin/hex file etc.
pico_add_extra_outputs(transmit)

# Pull in our pico_stdlib which pulls in commonly used features
target_link_libraries(transmit pico_stdlib)
