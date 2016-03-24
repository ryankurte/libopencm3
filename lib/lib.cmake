
# Glob and add library components defined in OPENCM3_LIBS
# to libopencm3

# Build target list
set(OPENCM3_TARGETS "stm32/f0; stm32/f1; stm32/f2; stm32/f3; stm32/f4; stm32/f7; \
	  stm32/l0; stm32/l1; stm32/l4; \
	  lpc13xx; lpc17xx; lpc43xx/m4; lpc43xx/m0; lm3s; lm4f; \
	  efm32/tg; efm32/g; efm32/lg; efm32/gg; \
	  sam/3a; sam/3n; sam/3s; sam/3u; sam/3x; \
	  vf6xx")

# TODO: check TARGET is in OPENCM3_TARGETS

# Calculate target components
# Hack to get around some devices having a two step path (and common files) and some not
string(REGEX MATCHALL "[a-zA-Z0-9]+" TARGET_PATH "${OPENCM3_TARGET}")

# Add core sources 
file(GLOB OPENCM3_LIB_SOURCES ${CMAKE_CURRENT_LIST_DIR}/cm3/*.c)

# Add target sources
set(TARGET_BASE ${CMAKE_CURRENT_LIST_DIR})

# Add parent folder if exists
list(GET TARGET_PATH 0 TARGET_TOP)
if(EXISTS "${TARGET_BASE}/${TARGET_TOP}" AND IS_DIRECTORY "${TARGET_BASE}/${TARGET_TOP}")
file(GLOB OPENCM3_TARGET_TOP_SOURCES ${TARGET_BASE}/${TARGET_TOP}/*.c)
endif()

# Add common folder if exists
# TODO: not sure if required
if(EXISTS "${TARGET_BASE}/${TARGET_TOP}/common" AND IS_DIRECTORY "${TARGET_BASE}/${TARGET_TOP}")
#file(GLOB OPENCM3_TARGET_COMMON_SOURCES ${TARGET_BASE}/${TARGET_TOP}/common/*common_all.c)
#set(COMMON_SOURCES vector.c systick.c scb.c nvic.c assert.c sync.c dwt.c) 

# TODO: manually defining here is awful
# How do the existing cmake files do it..?
set(OPENCM3_TARGET_COMMON_SOURCES
	${CMAKE_CURRENT_LIST_DIR}/stm32/common/rcc_common_all.c
	${CMAKE_CURRENT_LIST_DIR}/stm32/common/spi_common_all.c
	${CMAKE_CURRENT_LIST_DIR}/stm32/common/gpio_common_all.c
	${CMAKE_CURRENT_LIST_DIR}/stm32/common/gpio_common_f0234.c
	${CMAKE_CURRENT_LIST_DIR}/stm32/common/spi_common_f03.c
	${CMAKE_CURRENT_LIST_DIR}/stm32/common/flash_common_f01.c
	)
# TODO: Hacks for diferent types

endif()

# Locate linker script
file(GLOB OPENCM3_TARGET_LINKER_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/${OPENCM3_TARGET}/libopencm3_*.ld)
message("Located base linker script: ${OPENCM3_TARGET_LINKER_SCRIPT}")

# Add base folder (if different to parent folder)
if(NOT "${TARGET_TOP}" STREQUAL ${OPENCM3_TARGET})
file(GLOB OPENCM3_TARGET_BASE_SOURCES ${CMAKE_CURRENT_LIST_DIR}/${OPENCM3_TARGET}/*.c)
endif()

# Combine sources
set(OPENCM3_TARGET_SOURCES ${OPENCM3_TARGET_TOP_SOURCES} ${OPENCM3_TARGET_COMMON_SOURCES} ${OPENCM3_TARGET_BASE_SOURCES})
# Remove vector_nvic as it is wackily included via cm3/vector.c -> dispatch/vector_nvic.c
# This is required as #pragma weak must link against functions in the same unit
list(REMOVE_ITEM OPENCM3_TARGET_SOURCES "${CMAKE_CURRENT_LIST_DIR}/${OPENCM3_TARGET}/vector_nvic.c")

# Add components if required
if(DEFINED OPENCM3_USB)
file(GLOB_RECURSE OPENCM3_USB_SOURCES ${CMAKE_CURRENT_LIST_DIR}/usb/ *.c)
set(OPENCM3_LIB_SOURCES ${OPENCM3_LIB_SOURCES} ${OPENCM3_USB_SOURCES})
endif(DEFINED OPENCM3_USB)

# Build and include library
add_library(opencm3 ${OPENCM3_LIB_SOURCES} ${OPENCM3_TARGET_SOURCES})
set(LIBS ${LIBS} opencm3)
