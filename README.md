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

The application itself is one call: `app_main()` runs `espos_start()`, and
espOS brings up logging, config, the web UI, WiFi, SignalK, OTA and — because
`espos_ble` is in the build and Bluetooth is enabled — the gateway, in order.

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
different one) and nothing else: the espOS web UI is a committed bundle, so
there is no Node step.

```sh
git clone --recursive https://github.com/dirkwa/espos-ble-gateway
cd espos-ble-gateway
. ~/esp-idf-v6.0.2/export.sh

# esp32p4 here; esp32 / esp32s3 / esp32c3 / esp32c6 the same way
espos/scripts/build.sh -B build-esp32p4 -DSDKCONFIG=build-esp32p4/sdkconfig -DIDF_TARGET=esp32p4 build
idf.py -B build-esp32p4 -p /dev/ttyACM0 flash monitor
```

`espos/scripts/build.sh` is espOS's build wrapper — one build at a time per
machine, half the cores, `nice`/`ionice`, scratch kept off tmpfs; on a small
host that is the difference between a build and a frozen session.
`scripts/build.sh` forwards to it. Plain `idf.py set-target esp32p4 &&
idf.py build` is the same build without the babysitting.

The sdkconfig is assembled by espOS (`espos/docs/development.md`): its own
defaults first, then this project's `sdkconfig.defaults` (Bluetooth and the
little the gateway does differently), then a git-ignored `sdkconfig.local`
for personal overrides, then the partition table. Defaults reach a fresh
sdkconfig only — delete `build*/sdkconfig` after changing them.

## Setup

On first boot the device raises a WiFi provisioning portal (`espOS-xxxx`).
Join it and pick a network; from then on everything is at `http://<device>/`.

Credentials live in NVS, never in the firmware image. To provision without
the portal, see [espos/docs/wifi.md](espos/docs/wifi.md) — put them in a CSV
**outside the repo**, generate an NVS partition and flash it to `0x9000`.

The gateway finds a SignalK server over mDNS and requests access as
`ble_gateway <hostname>`; approve it in the server's admin UI under
Security → Access Requests. On a network with several servers, pin one with
`sk.server_host` and `sk.server_pin`.

Settings live under the `ble` namespace in the web UI. Defaults are sensible;
`active_scan` is off deliberately (see [espos/docs/ble.md](espos/docs/ble.md)).

## Status

`GET /api/v1/ble/status` reports scan, buffer and POST counters — enough to
tell a BLE problem from a server problem at a glance. Full description in
[espos/docs/rest-api.md](espos/docs/rest-api.md), and the component guide
with the troubleshooting notes is [espos/docs/ble.md](espos/docs/ble.md).

## Layout

```
espos/               espOS submodule: WiFi, config, web UI, SignalK, OTA, health,
                     and components/espos_ble - where the gateway actually lives
main/                app_main() = espos_start(); CMakeLists.txt names the
                     components that make this build a gateway (deliberately thin)
sdkconfig.defaults*  only what differs from espOS: Bluetooth, PSRAM on the P4
partitions.csv       16 MB: 2.5 MB OTA slots, LittleFS storage for the UI
scripts/build.sh     forwards to espos/scripts/build.sh
```

Anything that improves the gateway belongs in espOS, not here.

## History

This replaces [sensesp-ble-gateway](https://github.com/dirkwa/sensesp-ble-gateway)
(archived), which did the same job as a SensESP/Arduino library. The protocol
is unchanged, so a server configured for that gateway works with this one.

The rewrite exists mainly to get off Arduino, and it fixed several things on
the way: GATT writes now honour `with_response` (JK-BMS and Daly-BMS reject
write-with-response on their command characteristic), GATT operations act on
the connection they were given rather than the first one matching a UUID, and
advertisement drops are counted honestly.

Not carried over: the NimBLE / ESP32-C5 backend, which was scan-only. The
archived repository remains the only place that exists.

## License

Source available, not open source — see [LICENSE.md](LICENSE.md).
