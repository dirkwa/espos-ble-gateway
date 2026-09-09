/*
 * SPDX-FileCopyrightText: 2026 Dirk Wahrheit
 * SPDX-License-Identifier: Apache-2.0
 *
 * espos-ble-gateway: bridges BLE devices to signalk-server's BLE provider API.
 *
 * Everything of substance lives in espOS (espos/components/espos_ble), and so
 * does the boot order: espos_start() brings up the log ring, config, the HTTP
 * server, WiFi, SignalK, OTA and then the gateway, in the one order that works
 * (espos/docs/concepts.md). Which of the optional stacks it starts is decided
 * at configure time from main/CMakeLists.txt's component list — espos_ble is
 * in the build and Bluedroid is enabled in sdkconfig, so the gateway is one of
 * them — not by anything written here.
 */

#include "espos.h"

void app_main(void)
{
    ESP_ERROR_CHECK(espos_start(NULL));
}
