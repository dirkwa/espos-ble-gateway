# SPDX-License-Identifier: LicenseRef-Source-Available-No-Redistribution
#
# espos-ble-gateway: a pure ESP-IDF 6 project. WiFi, config, the web UI,
# SignalK discovery/token/stream and OTA come from the espOS submodule
# (espos/); this project adds board wiring for the BLE gateway, whose
# implementation lives in espOS's espos_ble component.
#
# Build:  . <IDF v6.0.2>/export.sh; idf.py set-target esp32p4; scripts/build.sh
cmake_minimum_required(VERSION 3.22)

file(READ "${CMAKE_CURRENT_LIST_DIR}/.idf-version" BLEGW_IDF_VERSION)
string(STRIP "${BLEGW_IDF_VERSION}" BLEGW_IDF_VERSION)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)

set(BLEGW_IDF_ACTUAL "v${IDF_VERSION_MAJOR}.${IDF_VERSION_MINOR}.${IDF_VERSION_PATCH}")
if(NOT BLEGW_IDF_ACTUAL STREQUAL BLEGW_IDF_VERSION AND NOT BLEGW_ALLOW_IDF_MISMATCH)
    message(FATAL_ERROR "ble-gateway: .idf-version pins ${BLEGW_IDF_VERSION} but IDF_PATH is ${BLEGW_IDF_ACTUAL} "
                        "(pass -DBLEGW_ALLOW_IDF_MISMATCH=1 to override).")
endif()

if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/espos/components/espos_config/CMakeLists.txt")
    message(FATAL_ERROR "ble-gateway: espos/ submodule is empty - run `git submodule update --init`.")
endif()
list(APPEND EXTRA_COMPONENT_DIRS "${CMAKE_CURRENT_LIST_DIR}/espos/components")

# App-signing key for espOS OTA (see espos/docs/ota.md); never committed.
set(BLEGW_SIGNING_KEY "${CMAKE_CURRENT_LIST_DIR}/secure_boot_signing_key.pem")
if(NOT EXISTS "${BLEGW_SIGNING_KEY}")
    message(WARNING "ble-gateway: no secure_boot_signing_key.pem - generating a development RSA-3072 signing key.")
    execute_process(COMMAND ${PYTHON} -m espsecure generate_signing_key --version 2 --scheme rsa3072 "${BLEGW_SIGNING_KEY}"
                    RESULT_VARIABLE rc OUTPUT_QUIET)
    if(NOT rc EQUAL 0)
        message(FATAL_ERROR "ble-gateway: could not generate secure_boot_signing_key.pem")
    endif()
endif()

# Re-sign when the KEY changes, not just when the code does.
#
# ESP-IDF's signing step depends on the unsigned binary alone
# (esptool_py/project_include.cmake: DEPENDS "${build_dir}/.bin_timestamp"),
# so swapping secure_boot_signing_key.pem and rebuilding silently keeps the
# signature made with the PREVIOUS key - the sources did not change, so
# nothing re-links. The build log looks completely normal. You get a device
# that installs fine over USB and then rejects every OTA, and the reason is
# invisible unless you run `espsecure verify-signature` by hand.
#
# Fingerprint the key (public part only - never the private key, this string
# reaches the build dir) and force a re-link whenever it differs.
file(SHA256 "${BLEGW_SIGNING_KEY}" BLEGW_SIGNING_KEY_HASH)
set(BLEGW_KEY_STAMP "${CMAKE_BINARY_DIR}/blegw_signing_key.stamp")
set(BLEGW_KEY_STAMP_OLD "")
if(EXISTS "${BLEGW_KEY_STAMP}")
    file(READ "${BLEGW_KEY_STAMP}" BLEGW_KEY_STAMP_OLD)
endif()
if(NOT BLEGW_KEY_STAMP_OLD STREQUAL BLEGW_SIGNING_KEY_HASH)
    if(NOT BLEGW_KEY_STAMP_OLD STREQUAL "")
        message(STATUS "ble-gateway: signing key changed - forcing a re-link so the "
                       "image is signed with the current key.")
        file(REMOVE "${CMAKE_BINARY_DIR}/.bin_timestamp"
                    "${CMAKE_BINARY_DIR}/.signed_bin_timestamp")
    endif()
    file(WRITE "${BLEGW_KEY_STAMP}" "${BLEGW_SIGNING_KEY_HASH}")
endif()

project(ble_gateway)

# espOS web UI -> LittleFS "storage" image (built in espos/ui by `npm run build`).
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/espos/ui/dist-gz/index.html.gz")
    littlefs_create_partition_image(storage "${CMAKE_CURRENT_LIST_DIR}/espos/ui/dist-gz" FLASH_IN_PROJECT)
else()
    # WARNING, not STATUS: a STATUS line disappears into cmake's output and the
    # device then silently serves espOS' placeholder page instead of the real
    # config UI, which looks like a firmware bug rather than a missing step.
    message(WARNING "ble-gateway: espos/ui/dist-gz missing - the device will serve the placeholder page, "
                    "not the espOS web UI. Build it with: scripts/build-ui.sh")
endif()
