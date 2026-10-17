# WhiskerLink Garmin

**WhiskerLink for Garmin** is an unofficial Connect IQ client for Bluetooth HVAC instruments.

Right now, it lets a **Garmin Instinct 2** talk directly to a **Testo 549i** pressure probe over BLE, without the official phone app.

## Current support

- Garmin Instinct 2 / Instinct 2 Solar
- Testo 549i
- Live pressure in psi
- Saturation temperature
- Dew and bubble temperatures where applicable
- R-404A, R-410A, R-22, R-134a, and R-290
- Zeroing from the watch
- Firmware, battery, and RSSI info

WhiskerLink is still early software and currently supports one probe at a time.

## Documentation

- [How to use WhiskerLink](docs/how-to-use.md)
- [How it works](docs/how-it-works.md)
- [Known quirks](docs/known-quirks.md)
- [Testo protocol documentation](https://github.com/whiskerlink/protocols)

## Building

You need the Garmin **Connect IQ SDK** and a developer signing key.

WhiskerLink is written in **Monkey C** and currently targets `instinct2`.

```sh
monkeyc \
  -f monkey.jungle \
  -o bin/WhiskerLink.prg \
  -y /path/to/developer_key \
  -d instinct2
```

### NixOS

The Connect IQ SDK includes Linux launcher scripts that may assume `/bin/bash`. On NixOS, their shebangs may need to be patched before the SDK tools will run normally.

## Installation

Connect the watch over USB and copy the built file to:

```text
GARMIN/APPS/WhiskerLink.prg
```

Disconnect the watch, then launch WhiskerLink from the app list.

## Project

WhiskerLink is about making useful hardware usable outside its vendor's preferred software stack.

The broader project aims to provide open protocol documentation and clients for platforms including Garmin, Linux, and Android.

## Disclaimer

WhiskerLink is an independent project and is not affiliated with or endorsed by Testo or Garmin.

It is experimental software. Verify important HVAC and refrigeration measurements with appropriate instruments and use professional judgment in the field.

WhiskerLink was written with AI assistance.
