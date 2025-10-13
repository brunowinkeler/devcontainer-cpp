set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_C_COMPILER_ID "GNU")
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_CXX_COMPILER_ID "GNU")
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)

# Adicionar opção para compilação estática
option(STATIC_BUILD "Build statically linked executable" ON)

message(STATUS "Configuring for static build - ${STATIC_BUILD}")
if(STATIC_BUILD)
    # Para compiladores GCC/MinGW (incluindo cross-compilation)
    if(CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
        set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
        set(BUILD_SHARED_LIBS OFF)
    endif()

    # Para MSVC
    if(MSVC)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /MT")
    endif()
endif()
