cmake_minimum_required(VERSION 3.0.0)
project(vanish C CXX)

set(APP_ID vanish.vitalsoft)
set(APP_NAME vanish)
set(DATA_DIR /)

# Click architecture written into the manifest. Precedence:
#   1. CLICK_ARCH_OVERRIDE environment variable (CI sets it per build: amd64 / arm64 / armhf)
#   2. -DCLICK_ARCH passed by clickable
#   3. "all": the app is pure QML, so one package runs on every device
if(DEFINED ENV{CLICK_ARCH_OVERRIDE} AND NOT "$ENV{CLICK_ARCH_OVERRIDE}" STREQUAL "")
    set(CLICK_ARCH "$ENV{CLICK_ARCH_OVERRIDE}")
elseif(NOT CLICK_ARCH)
    set(CLICK_ARCH all)
endif()
message(STATUS "Click architecture: ${CLICK_ARCH}")

# Clickable passes -DCLICK_FRAMEWORK; fall back for plain cmake runs.
if(NOT CLICK_FRAMEWORK)
    set(CLICK_FRAMEWORK ubuntu-sdk-20.04)
endif()

configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${APP_NAME}.apparmor ${APP_NAME}.desktop DESTINATION ${DATA_DIR})
install(DIRECTORY qml DESTINATION ${DATA_DIR})
install(DIRECTORY assets DESTINATION ${DATA_DIR})
