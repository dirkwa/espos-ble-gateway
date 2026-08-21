/*
 * SPDX-License-Identifier: LicenseRef-Source-Available-No-Redistribution
 *
 * espos-ble-gateway: bridges BLE devices to signalk-server's BLE provider API.
 *
 * Everything of substance lives in espOS (espos/components/espos_ble); this
 * app is the board wiring and the boot order.
 */

#include "espos_ble.h"
#include "espos_config.h"
#include "espos_httpd.h"
#include "espos_log.h"
#include "espos_ota.h"
#include "espos_sk.h"
#include "espos_wifi.h"

void app_main(void)
{
    /* Order is load-bearing: the log ring first so the boot log reaches
     * /api/v1/logs, config next because everything below reads it, then the
     * HTTP server before the components that register endpoints on it. */
    ESP_ERROR_CHECK(espos_log_init());
    ESP_ERROR_CHECK(espos_config_init(NULL, NULL));

    ESP_ERROR_CHECK(espos_httpd_start());
    ESP_ERROR_CHECK(espos_wifi_start());
    ESP_ERROR_CHECK(espos_sk_start());
    ESP_ERROR_CHECK(espos_ota_start());

    /* Last: it registers its own endpoint and wants the SignalK client up
     * before it looks for a server and a token. */
    ESP_ERROR_CHECK(espos_ble_start());
}
