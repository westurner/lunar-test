# CMakeLists.txt (Project Root)
cmake_minimum_required(VERSION 3.20)
project(lunarengine LANGUAGES C CXX)

# MSVC runtime (/MD)
if(MSVC)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
endif()

if(MSVC)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc /O2 /DNOMINMAX")
else()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall -Wextra")
endif()

# Paths
set(PROJ_ROOT "${CMAKE_SOURCE_DIR}")
set(VENDOR_DIR "${PROJ_ROOT}/third_party/vendor")

# ---------- Find Pre-built Luau lib ----------
set(LUAU_INSTALL_DIR "${VENDOR_DIR}/luau")
find_library(LUAU_LIB
  NAMES Luau
  PATHS "${LUAU_INSTALL_DIR}/lib"
  NO_DEFAULT_PATH
)
if(NOT LUAU_LIB)
  message(FATAL_ERROR "Luau library not found. Did you run build_dependencies.bat? Searched in: ${LUAU_INSTALL_DIR}/lib")
endif()
message(STATUS "Found Luau library: ${LUAU_LIB}")


# ---------- Find Pre-built Raylib lib ----------
set(RAYLIB_INSTALL_DIR "${VENDOR_DIR}/raylib")
if(WIN32)
  set(RAYLIB_LIB_NAMES raylib raylib_static)
else()
  set(RAYLIB_LIB_NAMES raylib libraylib.a)
endif()

find_library(RAYLIB_LIB
  NAMES ${RAYLIB_LIB_NAMES}
  PATHS "${RAYLIB_INSTALL_DIR}/lib"
  NO_DEFAULT_PATH
)
if(NOT RAYLIB_LIB)
  message(FATAL_ERROR "raylib library not found in ${RAYLIB_INSTALL_DIR}/lib")
endif()
message(STATUS "Found Raylib library: ${RAYLIB_LIB}")


# ---------- Engine exe ----------
file(GLOB_RECURSE ENGINE_SOURCES
  "${PROJ_ROOT}/bootstrap/*.cpp"
  "${PROJ_ROOT}/core/*.cpp"
  "${PROJ_ROOT}/services/*.cpp"
  "${PROJ_ROOT}/subsystems/*.cpp"
)
add_library(lunarengine_core STATIC ${ENGINE_SOURCES})
add_executable(lunarengine bootstrap/main.cpp)
target_link_libraries(lunarengine PRIVATE lunarengine_core ${LUAU_LIB} ${RAYLIB_LIB})

# ---vvv--- THE FIX IS HERE ---vvv---
# We now point to the specific subdirectories where the headers were installed,
# exactly like your original build script did.
target_include_directories(lunarengine_core PUBLIC
  "${CMAKE_BINARY_DIR}"
  "${PROJ_ROOT}"
  "${LUAU_INSTALL_DIR}/include/luau/Common/include"
  "${LUAU_INSTALL_DIR}/include/luau/Ast/include"
  "${LUAU_INSTALL_DIR}/include/luau/Compiler/include"
  "${LUAU_INSTALL_DIR}/include/luau/Config/include"
  "${LUAU_INSTALL_DIR}/include/luau/VM/include"
  "${RAYLIB_INSTALL_DIR}/include"
)
target_include_directories(lunarengine PRIVATE
  "${CMAKE_BINARY_DIR}"
  "${PROJ_ROOT}"
)
# ---^^^--- THE FIX IS HERE ---^^^---

target_compile_features(lunarengine_core PUBLIC cxx_std_20)
target_compile_features(lunarengine PRIVATE cxx_std_20)

if(MSVC)
  target_compile_options(lunarengine_core PUBLIC /EHsc /O2 /DNOMINMAX)
  target_compile_options(lunarengine PRIVATE /EHsc /O2 /DNOMINMAX)
endif()

add_subdirectory(tests)

# ---------- Linking ----------
target_link_libraries(lunarengine PRIVATE ${LUAU_LIB} ${RAYLIB_LIB})
if(WIN32)
  target_link_libraries(lunarengine PRIVATE opengl32 gdi32 winmm user32 shell32)
elseif(UNIX AND NOT APPLE)
  target_link_libraries(lunarengine PRIVATE GL X11 pthread dl m)
endif()


# ---------- Installation (The new "Dist" step) ----------
install(TARGETS lunarengine
  RUNTIME DESTINATION .
)
set(CONTENT_SRC "${PROJ_ROOT}/content/dist")
if(EXISTS "${CONTENT_SRC}")
  install(DIRECTORY "${CONTENT_SRC}/"
    DESTINATION .
  )
endif()

# Add version resource on Windows
if(WIN32)
  target_sources(lunarengine PRIVATE "${PROJ_ROOT}/lunarengine.rc")
endif()

# Set final output name
set_target_properties(lunarengine PROPERTIES OUTPUT_NAME "LunarApp")

# Include the git revhash in the build for traceability
# Set version string and get git commit hash
# Append an underscore '_' to the commit hash if there are uncommited changes at build time
find_package(Git QUIET)
if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} status --porcelain
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_STATUS
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT "${GIT_STATUS}" STREQUAL "")
        set(GIT_HASH "${GIT_HASH}_")
    endif()
else()
    set(GIT_HASH "nogit")
endif()

# Generate Version.h at build time
set(VERSION_HEADER_PATH "${CMAKE_BINARY_DIR}/Version.h")
configure_file(
    "${CMAKE_SOURCE_DIR}/Version.h.in"
    "${VERSION_HEADER_PATH}"
    @ONLY
)

