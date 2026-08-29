# SPDX-License-Identifier: LicenseRef-Source-Available-No-Redistribution
#
# espos-ble-gateway: a pure ESP-IDF 6 project. WiFi, config, the web UI,
# SignalK discovery/token/stream and OTA come from the espOS submodule
# (espos/); this project adds board wiring for the BLE gateway, whose
# implementation lives in espOS's espos_ble component.
#
# Build:  . <IDF v6.0.2>/export.sh; idf.py set-target esp32p4; scripts/build.sh
cmake_minimum_required(VERSION 3.22)

# The IDF version pin, espos/components on EXTRA_COMPONENT_DIRS, the signing
# key and the re-sign-on-key-change workaround all live in espOS now. They
# used to be ~55 lines copied into this file, the cockpit's and espOS's own,
# which had already started to drift — and the signing half of it is exactly
# the code that must not, since getting it wrong yields a gateway that
# flashes fine over USB and then rejects every OTA.
include("${CMAKE_CURRENT_LIST_DIR}/espos/cmake/espos_project.cmake")
espos_project_prologue(NAME "ble-gateway")

project(ble_gateway)

# espOS web UI → LittleFS "storage" image (built in espos/ui by `npm run build`).
espos_project_ui_partition(NAME "ble-gateway")
