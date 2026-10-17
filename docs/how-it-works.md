# How WhiskerLink works

WhiskerLink talks directly from the Garmin watch to the Testo 549i over Bluetooth Low Energy.

The watch:

1. scans for the probe
2. connects over BLE
3. enables Testo notifications
4. performs the startup handshake
5. starts the live data stream
6. parses pressure and battery data
7. calculates saturation temperature locally

For the Testo data channel, WhiskerLink uses:

- service `FFF0`
- write characteristic `FFF1`
- notify characteristic `FFF2`

Testo packets have their own framing and CRC inside BLE. WhiskerLink also reassembles packets across notification boundaries and splits large writes to fit Connect IQ's BLE write limit.

Pressure/temperature conversion is done locally on the watch from built-in PT tables.

For protocol details, see the [WhiskerLink protocols repository](https://github.com/whiskerlink/protocols).
