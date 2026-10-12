# SPDX-FileCopyrightText: 2026 Dirk Wahrheit
# SPDX-License-Identifier: Apache-2.0
#
# espos-ble-gateway: a pure ESP-IDF 6 project. WiFi, config, the web UI,
# SignalK discovery/token/stream, OTA and the BLE gateway itself all come from
# the espOS submodule (espos/); this project is the board wiring: which
# components are in the build (main/CMakeLists.txt), which partition table,
# and the few sdkconfig lines that differ from espOS's.
#
# Build:  . <IDF v6.0.3>/export.sh
#         espos/scripts/build.sh -B build-esp32p4 -DSDKCONFIG=build-esp32p4/sdkconfig -DIDF_TARGET=esp32p4 build
cmake_minimum_required(VERSION 3.22)

# The IDF version pin, espOS's sdkconfig defaults, its components on
# EXTRA_COMPONENT_DIRS, the signing key and the re-sign-on-key-change
# workaround all live in espOS's prologue (espos/docs/development.md,
# "Building a firmware on espOS"). They used to be ~55 lines of CMake plus a
# mirrored sdkconfig.defaults in every project, which had already started to
# drift — and the signing half of it is exactly the code that must not, since
# getting it wrong yields a gateway that flashes fine over USB and then
# rejects every OTA.
#
# Own partition table rather than the bundled espos/partitions/16mb.csv: the
# slot offsets differ, and a device keeps the table it was flashed with — OTA
# replaces app slots, never the table — so switching would turn the next
# update into a USB reflash. partitions.csv explains its sizing.
include("${CMAKE_CURRENT_LIST_DIR}/espos/cmake/espos_project.cmake")
espos_project_prologue(NAME "ble-gateway" PARTITIONS "${CMAKE_CURRENT_LIST_DIR}/partitions.csv"
                       COMPONENTS espos_ble espos_eth)

project(ble_gateway)

# The ESP32-C5 runs this firmware only on espOS 0.18.0 or newer: PSRAM in use
# (sdkconfig.defaults.esp32c5) needs espOS's TLS pre-flight to measure PSRAM,
# and a shared radio needs the gateway to stop scanning while the station
# associates (signalk-espOS/espOS#207). Built against an older espos submodule,
# the image would still boot -- and refuse every TLS handshake and take minutes
# to join WiFi. Refusing the build is what keeps such an image out of a release.
idf_build_get_property(_target IDF_TARGET)
file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/espos/version.txt" _espos_version LIMIT_COUNT 1)
if(_target STREQUAL "esp32c5" AND _espos_version VERSION_LESS "0.18.0")
    message(FATAL_ERROR "ble-gateway on esp32c5 needs espOS >= 0.18.0; the espos submodule is at ${_espos_version}")
endif()

# The committed espOS web UI (espos/ui/dist-gz) → LittleFS "storage" image,
# flashed with `idf.py flash`. No Node step anywhere.
espos_project_ui_partition(NAME "ble-gateway")
