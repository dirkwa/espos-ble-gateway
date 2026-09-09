# SPDX-FileCopyrightText: 2026 Dirk Wahrheit
# SPDX-License-Identifier: Apache-2.0
#
# espos-ble-gateway: a pure ESP-IDF 6 project. WiFi, config, the web UI,
# SignalK discovery/token/stream, OTA and the BLE gateway itself all come from
# the espOS submodule (espos/); this project is the board wiring: which
# components are in the build (main/CMakeLists.txt), which partition table,
# and the few sdkconfig lines that differ from espOS's.
#
# Build:  . <IDF v6.0.2>/export.sh
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
                       COMPONENTS espos_ble)

project(ble_gateway)

# The committed espOS web UI (espos/ui/dist-gz) → LittleFS "storage" image,
# flashed with `idf.py flash`. No Node step anywhere.
espos_project_ui_partition(NAME "ble-gateway")
