# Changelog

## [0.3.1](https://github.com/dirkwa/espos-ble-gateway/compare/v0.3.0...v0.3.1) (2026-09-24)


### Fixed

* bump espos to v0.10.3 for the two C5 stability fixes ([#22](https://github.com/dirkwa/espos-ble-gateway/issues/22)) ([dd0c8c0](https://github.com/dirkwa/espos-ble-gateway/commit/dd0c8c0370d1810420ccd674753fe43d10859398))
* **esp32c5:** size the WiFi buffers for this chip, and harden the release mirror ([#20](https://github.com/dirkwa/espos-ble-gateway/issues/20)) ([72cb9b8](https://github.com/dirkwa/espos-ble-gateway/commit/72cb9b8ce0cef68749fd0822d732b1b22a80c04c))

## [0.3.0](https://github.com/dirkwa/espos-ble-gateway/compare/v0.2.0...v0.3.0) (2026-09-22)


### Added

* **ci:** release firmware for every chip, and add esp32c5 ([#12](https://github.com/dirkwa/espos-ble-gateway/issues/12)) ([e349d92](https://github.com/dirkwa/espos-ble-gateway/commit/e349d92ce90bd2603a5301d047ca6c1cb003ad3f))
* **eth:** carry the network on the PoE cable, WiFi off ([#8](https://github.com/dirkwa/espos-ble-gateway/issues/8)) ([89cb152](https://github.com/dirkwa/espos-ble-gateway/commit/89cb1527eaa779788e7efd3fc9096470e088743a))


### Fixed

* **ci:** forward the signing key to the firmware build, so releases are signed ([#16](https://github.com/dirkwa/espos-ble-gateway/issues/16)) ([9183fd9](https://github.com/dirkwa/espos-ble-gateway/commit/9183fd9e8d39669fae587ba55f84f19e2ac3e682))
