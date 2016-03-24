# Set minimum CMake version
cmake_minimum_required(VERSION 3.3)

# Set the compiler (must be prior to project setup)
include(./libopencm3/toolchain/arm-gcc.cmake)

##### Project Setup #####

# Set our output target
set(TARGET opencm3-test)

# Configure project and languages
project(${TARGET} C CXX ASM)

# Set device
set(OPENCM3_TARGET	stm32/f0)
set(DEVICE 			STM32F072RBT6)
set(FAMILY 			STM32F0)
set(CORE 			m0)

set(RAM_START		0x20000000)
set(RAM_LENGTH		16k)
set(ROM_START		0x08000000)
set(ROM_LENGTH		128k)

# Set build
if(NOT CMAKE_BUILD_TYPE)
set(CMAKE_BUILD_TYPE DEBUG)
endif()

##### Modules #####

# Libraries can be added to the LIBS variable
# or manually included here.

include(${PROJECT_SOURCE_DIR}/libopencm3/opencm3.cmake)

##### Files #####

# Add project headers
include_directories(${PROJECT_SOURCE_DIR}/include)

# Add project sources
set(SOURCES
	source/main.cpp
)

##### Outputs #####

# Generate executable and link
add_executable(${TARGET} ${SOURCES})
target_link_libraries(${TARGET} ${LIBS})

