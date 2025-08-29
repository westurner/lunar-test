# GoogleTest integration for librebox
# Add GoogleTest as a subdirectory
add_subdirectory(../third_party/googletest googletest)

# Test sources
file(GLOB TEST_SOURCES "${CMAKE_CURRENT_LIST_DIR}/*.cpp")
add_executable(lunarengine_tests ${TEST_SOURCES})


# Link with GoogleTest and project libraries
set(LUAU_INSTALL_DIR "${CMAKE_CURRENT_LIST_DIR}/../third_party/vendor/luau")
set(RAYLIB_INSTALL_DIR "${CMAKE_CURRENT_LIST_DIR}/../third_party/vendor/raylib")
find_library(LUAU_LIB NAMES Luau PATHS "${LUAU_INSTALL_DIR}/lib" NO_DEFAULT_PATH)
find_library(RAYLIB_LIB NAMES raylib raylib_static PATHS "${RAYLIB_INSTALL_DIR}/lib" NO_DEFAULT_PATH)

target_include_directories(lunarengine_tests PRIVATE 
    ${CMAKE_CURRENT_LIST_DIR}/../third_party/googletest/googletest/include
    ${CMAKE_CURRENT_LIST_DIR}/../third_party/googletest/googletest

    ${CMAKE_BINARY_DIR}
    #${PROJ_ROOT}/..
    ${PROJ_ROOT}
    ${LUAU_INSTALL_DIR}/include/luau/Common/include
    ${LUAU_INSTALL_DIR}/include/luau/Ast/include
    ${LUAU_INSTALL_DIR}/include/luau/Compiler/include
    ${LUAU_INSTALL_DIR}/include/luau/Config/include
    ${LUAU_INSTALL_DIR}/include/luau/VM/include
    ${RAYLIB_INSTALL_DIR}/include
    ${LUAU_INSTALL_DIR}/include/luau/Compiler/include

)
target_link_libraries(lunarengine_tests PRIVATE gtest_main lunarengine_core ${LUAU_LIB} ${RAYLIB_LIB})

# Enable C++20 for tests
set_target_properties(lunarengine_tests PROPERTIES CXX_STANDARD 20)

# Add to CTest with per-test discovery
include(GoogleTest)
gtest_discover_tests(lunarengine_tests)
