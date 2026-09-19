# Bare-metal ARM builds with the Arm GNU Toolchain installed in /opt/gcc-arm-none-eabi.
# Copy this file into your project and adjust ARM_CPU_FLAGS to your MCU.

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# A bare-metal toolchain cannot link a runnable executable during compiler detection.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(ARM_TOOLCHAIN_PREFIX arm-none-eabi-)

find_program(CMAKE_C_COMPILER ${ARM_TOOLCHAIN_PREFIX}gcc REQUIRED)
find_program(CMAKE_CXX_COMPILER ${ARM_TOOLCHAIN_PREFIX}g++ REQUIRED)
find_program(CMAKE_ASM_COMPILER ${ARM_TOOLCHAIN_PREFIX}gcc REQUIRED)
find_program(CMAKE_AR ${ARM_TOOLCHAIN_PREFIX}ar REQUIRED)
find_program(CMAKE_RANLIB ${ARM_TOOLCHAIN_PREFIX}ranlib REQUIRED)
find_program(CMAKE_OBJCOPY ${ARM_TOOLCHAIN_PREFIX}objcopy REQUIRED)
find_program(CMAKE_OBJDUMP ${ARM_TOOLCHAIN_PREFIX}objdump REQUIRED)
find_program(CMAKE_SIZE ${ARM_TOOLCHAIN_PREFIX}size REQUIRED)

# The image ships gdb-multiarch instead of arm-none-eabi-gdb to keep the toolchain small.
find_program(CMAKE_GDB gdb-multiarch REQUIRED)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(ARM_CPU_FLAGS "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard")

set(CMAKE_C_FLAGS_INIT "${ARM_CPU_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS_INIT "${ARM_CPU_FLAGS} -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti")
set(CMAKE_ASM_FLAGS_INIT "${ARM_CPU_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${ARM_CPU_FLAGS} --specs=nano.specs --specs=nosys.specs -Wl,--gc-sections")
