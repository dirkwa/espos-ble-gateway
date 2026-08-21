# SPDX-License-Identifier: LicenseRef-Source-Available-No-Redistribution
idf_component_register(
    SRCS main.c
    INCLUDE_DIRS "."
    PRIV_REQUIRES espos_config espos_log espos_httpd espos_wifi espos_sk espos_ota espos_ble)
