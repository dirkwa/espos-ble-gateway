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

| Board | Radio | Flash | Status |
|---|---|---|---|
| Waveshare ESP32-P4 (+ ESP32-C6 over SDIO) | HCI at the C6 via esp_hosted | 16 MB | verified |
| ESP32 / C3 / S3 / C6 / C5 | native Bluedroid | 16 MB as shipped | builds; not yet run |

**As cloned, this builds a 16 MB image on every target**: `partitions.csv` is a
16 MB table and `sdkconfig.defaults` sets `CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y`.
Bluedroid is large — the image measures 2.13 MB on an ESP32-C6 — so two 2.5 MB
OTA slots plus the web-UI storage partition come to 5.94 MB, which is why the
table is sized the way it is. `esptool.py flash_id` reports the flash size of a
board you are unsure about.

A **4 MB** board cannot hold that table at all: it runs past the end of the
chip, and the flash fails partway through writing rather than because the board
is short of RAM (issue #4).

### Other flash sizes

Both paths below are edits to this repository, not options it ships with.

Neither has been booted here — there is no 4 MB or 8 MB board on this bench —
so both are starting points rather than supported configurations. What was
checked is that each builds for `esp32c6` with zero warnings and that the image
fits the slot, which is not the same as a device that runs.

**8 MB, keeping OTA.** Point the prologue at espOS's own 8 MB table (3 MB
slots, ample for a 2.13 MB image) and delete the flash-size line, because a
bundled `<n>mb.csv` makes the prologue set the size itself:

```cmake
espos_project_prologue(NAME "ble-gateway"
                       PARTITIONS "${ESPOS_PARTITIONS_DIR}/8mb.csv"
                       COMPONENTS espos_ble espos_eth)
```
```diff
-CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y
```

**4 MB, without OTA.** One `factory` slot holds the image at 71 % with the UI
storage intact. The cost is absolute rather than a degradation: `esp_https_ota`
needs a passive slot and fails without one, so **every update becomes a USB
reflash**.

The table ships as [`partitions-4mb.csv`](partitions-4mb.csv), so this is two
edits. The first is the one that is easy to miss: the prologue still names
`partitions.csv` otherwise, so the 16 MB table gets selected and the flash
fails exactly as in #4.

```cmake
espos_project_prologue(NAME "ble-gateway"
                       PARTITIONS "${CMAKE_CURRENT_LIST_DIR}/partitions-4mb.csv"
                       COMPONENTS espos_ble espos_eth)
```

A project's own table sets no flash size, unlike a bundled `<n>mb.csv`, so the
second edit states it:

```diff
-CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y
+CONFIG_ESPTOOLPY_FLASHSIZE_4MB=y
```

Verified by building it for `esp32c6`: `0x221000` in a `0x300000` slot, zero
warnings.

The ESP32-P4 has no radio of its own, so Bluetooth (like WiFi) runs over the
C6 co-processor. Nothing needs flashing on the C6 — its stock firmware
already carries BLE with HCI over SDIO.

**On the P4, check the antenna first.** The ESP32-C6-MINI-**1U** module has no
PCB antenna; without an external 2.4 GHz antenna on its IPEX connector the
radio sees nothing at all.

## Build

Needs ESP-IDF exactly `v6.0.3` (pinned in `.idf-version`, kept equal to the
espOS submodule's pin — the build refuses a
different one) and nothing else: the espOS web UI is a committed bundle, so
there is no Node step.

```sh
git clone --recursive https://github.com/dirkwa/espos-ble-gateway
cd espos-ble-gateway
. ~/esp-idf-v6.0.3/export.sh

# esp32p4 here; esp32 / esp32s3 / esp32c3 / esp32c6 / esp32c5 the same way
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

## Releases

`release-please` watches `main`, opens a `chore: release <version>` pull request,
and merging that tags the release and triggers `release-firmware.yml`, which
builds every supported chip and attaches both images per target (merged for a
cable, app-only for an OTA).

Two repository settings have to be right, and neither fails in a way that tells
you so:

* **Settings → Actions → General → "Allow GitHub Actions to create and approve
  pull requests"** must be enabled, and workflow permissions set to read/write.
  Without it release-please cannot open its release PR and the run fails with
  *"This run likely failed because of a workflow file issue"* and **zero jobs
  executed** — no job log, and nothing wrong with the workflow file. This cost
  three wrong diagnoses; `actionlint` passing while the run still fails is the
  signal that it is a permission, not the YAML.
* **`GATEWAY_SIGNING_KEY_PEM`** must hold the app-signing key:

  ```sh
  gh secret set GATEWAY_SIGNING_KEY_PEM --repo <owner>/<repo> < signing_key.pem
  ```

  A release built without it uses a per-run throwaway key: it installs over USB
  and then refuses every future OTA, on the boat, months later. The workflow
  fails closed rather than let that happen.

## Layout

```
espos/               espOS submodule: WiFi, config, web UI, SignalK, OTA, health,
                     and components/espos_ble - where the gateway actually lives
main/                app_main() = espos_start(); CMakeLists.txt names the
                     components that make this build a gateway (deliberately thin)
sdkconfig.defaults*  only what differs from espOS: Bluetooth, PSRAM on the P4
partitions.csv       needs 16 MB: 2.5 MB OTA slots, LittleFS storage for the UI
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

Not carried over: that gateway's **NimBLE** backend, which was scan-only. The
archived repository remains the only place it exists.

The C5 itself is built here (Bluedroid, like the other native-radio chips) but
has not been run on hardware -- the table above says so. It is in CI and in the
release matrix so an image exists to test with; treat it as build-tested, not
verified.

## License

Apache-2.0 — see [LICENSE](LICENSE). Relicensed from the previous
source-available terms in 2026 so that this firmware could be folded into
espOS, which is Apache-2.0.

## This firmware now also lives in espOS

The same gateway is an espOS example, at
[`components/espos_ble/examples/ble_gateway`](https://github.com/signalk-espOS/espOS/tree/main/components/espos_ble/examples/ble_gateway).
It is built by espOS's own CI on every change, which this repository is not,
so the example is the copy that cannot drift out of step with the component it
configures. Prefer it unless you want this repository's release history or its
own partition table.
