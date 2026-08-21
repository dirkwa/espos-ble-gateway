# espos-ble-gateway

BLE → SignalK gateway firmware, built on [espOS](https://github.com/dirkwa/espOS).

Scans for Bluetooth Low Energy devices and bridges them to
[signalk-server](https://github.com/SignalK/signalk-server)'s BLE provider
API: advertisements are batched over HTTP, and the server drives GATT
sessions (connect, subscribe, read, write) over a control WebSocket.

The gateway decodes nothing. What a device *is* — a battery monitor, a tank
sender, a thermometer — and how its bytes become SignalK paths is decided on
the server by `bt-sensors-plugin-sk`. That keeps the firmware small and means
adding support for a new sensor never involves reflashing anything.

## Hardware

| Board | Radio | Status |
|---|---|---|
| Waveshare ESP32-P4 (+ ESP32-C6 over SDIO) | HCI at the C6 via esp_hosted | verified |
| ESP32 / C3 / S3 / C6 | native Bluedroid | builds; not yet run |

The ESP32-P4 has no radio of its own, so Bluetooth (like WiFi) runs over the
C6 co-processor. Nothing needs flashing on the C6 — its stock firmware
already carries BLE with HCI over SDIO.

**On the P4, check the antenna first.** The ESP32-C6-MINI-**1U** module has no
PCB antenna; without an external 2.4 GHz antenna on its IPEX connector the
radio sees nothing at all.

## Build

Needs ESP-IDF exactly `v6.0.2` (pinned in `.idf-version`; the build refuses a
different one).

```sh
git clone --recursive https://github.com/dirkwa/espos-ble-gateway
cd espos-ble-gateway
. ~/esp-idf-v6.0.2/export.sh

scripts/build-ui.sh              # espOS web UI -> LittleFS image (optional but wanted)
idf.py set-target esp32p4        # or esp32 / esp32s3 / esp32c3 / esp32c6
scripts/build.sh                 # nice/ionice-wrapped; plain `idf.py build` also works
idf.py -p /dev/ttyACM0 flash monitor
```

Skipping `build-ui.sh` is survivable: the device then serves espOS's
placeholder page instead of the config UI.

## Setup

On first boot the device raises a WiFi provisioning portal (`espOS-xxxx`).
Join it and pick a network; from then on everything is at `http://<device>/`.

Credentials live in NVS, never in the firmware image. To provision without
the portal, see [espos/docs/wifi.md](espos/docs/wifi.md) — put them in a CSV
**outside the repo**, generate an NVS partition and flash it to `0x9000`.

The gateway finds a SignalK server over mDNS and requests access; approve it
in the server's admin UI under Security → Access Requests. On a network with
several servers, pin one with `sk.server_host` and `sk.server_pin`.

Settings live under the `ble` namespace in the web UI. Defaults are sensible;
`active_scan` is off deliberately (see [espos/docs/ble.md](espos/docs/ble.md)).

## Status

`GET /api/v1/ble/status` reports scan, buffer and POST counters — enough to
tell a BLE problem from a server problem at a glance. Full description in
[espos/docs/api.md](espos/docs/api.md), and the component guide with the
troubleshooting notes is [espos/docs/ble.md](espos/docs/ble.md).

## Layout

```
espos/          espOS submodule: WiFi, config, web UI, SignalK, OTA,
                and components/espos_ble - where the gateway actually lives
main/           boot order and board wiring; deliberately thin
partitions.csv  16 MB: 2 MB OTA slots, LittleFS storage for the UI
scripts/        build helpers
```

Anything that improves the gateway belongs in espOS, not here.

## License

Source available, not open source — see [LICENSE.md](LICENSE.md).
