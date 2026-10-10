# Changelog

## [1.0.3](https://github.com/dirkwa/espos-ble-gateway/compare/v1.0.2...v1.0.3) (2026-10-10)


### Fixed

* bump espOS to v0.16.1 ([#34](https://github.com/dirkwa/espos-ble-gateway/issues/34)) ([872dea7](https://github.com/dirkwa/espos-ble-gateway/commit/872dea7ec6a816e0338eccc9f6fc949de3a6b31a))

## [1.0.2](https://github.com/dirkwa/espos-ble-gateway/compare/v1.0.1...v1.0.2) (2026-10-10)


### Fixed

* bump espOS to v0.16.0 ([#32](https://github.com/dirkwa/espos-ble-gateway/issues/32)) ([005065d](https://github.com/dirkwa/espos-ble-gateway/commit/005065d8ffabdb7c847d1907fde808d58d66b8ef))

## [1.0.1](https://github.com/dirkwa/espos-ble-gateway/compare/v1.0.0...v1.0.1) (2026-10-09)


### Fixed

* **p4:** run on every Waveshare P4 board, not only PoE ([#29](https://github.com/dirkwa/espos-ble-gateway/issues/29)) ([aaca9d8](https://github.com/dirkwa/espos-ble-gateway/commit/aaca9d867e784249172e6b56b12b2927db30b655))

## [1.0.0](https://github.com/dirkwa/espos-ble-gateway/compare/v0.3.2...v1.0.0) (2026-10-03)


### ⚠ BREAKING CHANGES

* espOS v0.14.0, which moves the hosted transport to esp_hosted 3.x ([#26](https://github.com/dirkwa/espos-ble-gateway/issues/26))

### Internal

* espOS v0.14.0, which moves the hosted transport to esp_hosted 3.x ([#26](https://github.com/dirkwa/espos-ble-gateway/issues/26)) ([17d9d1a](https://github.com/dirkwa/espos-ble-gateway/commit/17d9d1a5ebcd5709612845c9f2089c651d8bd58c))

## [0.3.2](https://github.com/dirkwa/espos-ble-gateway/compare/v0.3.1...v0.3.2) (2026-09-24)


### Fixed

* **ci:** roll the mirror back on any failure, not only a failed attach ([#23](https://github.com/dirkwa/espos-ble-gateway/issues/23)) ([400baa5](https://github.com/dirkwa/espos-ble-gateway/commit/400baa5647ab9699e801006a4e69c9008b6ab09f))

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
