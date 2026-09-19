# Cross-compile Linux -> Windows x86_64 with the mingw-w64 toolchain shipped in the image.
# Copy this file into your project as cmake/toolchain-windows-mingw.cmake.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(MINGW_TARGET x86_64-w64-mingw32)

set(CMAKE_C_COMPILER ${MINGW_TARGET}-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_TARGET}-g++)
set(CMAKE_RC_COMPILER ${MINGW_TARGET}-windres)
set(CMAKE_AR ${MINGW_TARGET}-ar)
set(CMAKE_RANLIB ${MINGW_TARGET}-ranlib)

# Without these, find_package() can resolve host Linux libraries into a Windows build.
set(CMAKE_FIND_ROOT_PATH /usr/${MINGW_TARGET})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(STATIC_BUILD ON CACHE BOOL "Link the Windows executable statically")

if(STATIC_BUILD)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    # Yields a self-contained .exe: no libgcc, libstdc++ or libwinpthread DLLs to ship.
    set(CMAKE_EXE_LINKER_FLAGS_INIT "-static")
endif()
