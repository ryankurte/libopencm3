
# Check for required variables
if(NOT DEFINED DEVICE)
message(FATAL_ERROR "No DEVICE defined")
endif(NOT DEFINED DEVICE)

if(NOT DEFINED FAMILY)
message(FATAL_ERROR "No processor FAMILY (ie. STM32F0) defined")
endif(NOT DEFINED FAMILY)

if(NOT DEFINED CORE)
message(FATAL_ERROR "No processor CORE (ie. m0, m4) defined")
endif(NOT DEFINED CORE)

if(NOT DEFINED OPENCM3_TARGET)
message(FATAL_ERROR "No OPENCM3_TARGET defined")
endif(NOT DEFINED OPENCM3_TARGET)

# TODO: validate variables
if (NOT "${CORE}" MATCHES "^(m0|m0+|m3|m4|m7)$")
message(FATAL_ERROR "Invalid processor core")
endif()

# Generate nvic headers
message("Generating nvic headers from .json source files")
file(GLOB_RECURSE IRQ_DEFN_FILES RELATIVE ${CMAKE_CURRENT_LIST_DIR} */irq.json)
foreach(C ${IRQ_DEFN_FILES})
execute_process(COMMAND ${CMAKE_CURRENT_LIST_DIR}/scripts/irq2nvic_h ./${C} 
				WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
endforeach()

# Setup standard definitions
# CPU type for compiler + linker
add_definitions("-mcpu=cortex-${CORE} -mthumb")
# Additional warnings (good practice)
add_definitions("-Wextra -Wall")
# Split functions and data sections to enable linker --gc-sections
add_definitions("-ffunction-sections -fdata-sections")
# Create dependency map files
set(DEPFLAGS "-MMD -MP")

# Add core includes
include_directories(${CMAKE_CURRENT_LIST_DIR}/include)

# Add device definitions 
add_definitions("-D${DEVICE} -D${FAMILY}")

# Include libopencm3 libraries
include(${CMAKE_CURRENT_LIST_DIR}/lib/lib.cmake)

# Build linker script if not defined
if(NOT DEFINED LINKER_SCRIPT)

	# Check required fields are available
	if(NOT DEFINED RAM_START)
	message(FATAL_ERROR "No RAM_START defined")
	endif(NOT DEFINED RAM_START)

	if(NOT DEFINED RAM_LENGTH)
	message(FATAL_ERROR "No RAM_LENGTH defined")
	endif(NOT DEFINED RAM_LENGTH)

	if(NOT DEFINED ROM_START)
	message(FATAL_ERROR "No ROM_START defined")
	endif(NOT DEFINED ROM_START)

	if(NOT DEFINED ROM_LENGTH)
	message(FATAL_ERROR "No ROM_LENGTH defined")
	endif(NOT DEFINED ROM_LENGTH)

	set(LINKER_SCRIPT "${DEVICE}.ld")
	configure_file(${CMAKE_CURRENT_LIST_DIR}/linker.ld.in
		${PROJECT_BINARY_DIR}/${LINKER_SCRIPT}
	)
endif()

# Enable FLTO optimization if required
if(USE_FLTO)
	set(OPTFLAGS "-Os -flto")
else()
	set(OPTFLAGS "-Os")
endif()

# Build flags
set(CMAKE_C_FLAGS "-std=gnu11 --specs=nano.specs ${DEPFLAGS}")
set(CMAKE_CXX_FLAGS "-std=gnu++11 --specs=nano.specs ${DEPFLAGS}")
set(CMAKE_ASM_FLAGS "-x assembler-with-cpp")
set(CMAKE_EXE_LINKER_FLAGS "-Xlinker -T${LINKER_SCRIPT} -Wl,-Map=${CMAKE_PROJECT_NAME}.map -Wl,--gc-sections")

# Set default libraries to link
set(LIBS -lgcc -lc -lm ${LIBS} -lnosys )

# Debug Flags
set(COMMON_DEBUG_FLAGS "-O0 -g -gdwarf-2")
set(CMAKE_C_FLAGS_DEBUG   "${COMMON_DEBUG_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "${COMMON_DEBUG_FLAGS}")
set(CMAKE_ASM_FLAGS_DEBUG "${COMMON_DEBUG_FLAGS}")

# Release Flags
set(COMMON_RELEASE_FLAGS "${OPTFLAGS} -DNDEBUG=1 -DRELEASE=1")
set(CMAKE_C_FLAGS_RELEASE 	"${COMMON_RELEASE_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "${COMMON_RELEASE_FLAGS}")
set(CMAKE_ASM_FLAGS_RELEASE "${COMMON_RELEASE_FLAGS}")


# Post build commands 

# ARM post build commands

# Create other file types
add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${OBJCOPY} -O binary ${TARGET} ${TARGET}.bin)
add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${OBJCOPY} -O ihex ${TARGET} ${TARGET}.hex)
add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${OBJDUMP} -d -S ${TARGET} > ${TARGET}.dmp)
