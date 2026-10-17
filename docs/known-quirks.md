# Known quirks

## BLE scan can occasionally get stuck

On the Instinct 2, BLE scanning has occasionally stopped returning useful results even though the app still appears to be scanning.

If a known-good probe is powered on and WhiskerLink stays at `Scanning...`, rebooting the watch has restored scanning during testing.

## One probe at a time

The Garmin client currently supports one probe at a time.

Testing with multiple identical Testo probes showed Garmin accepting more than one device into the paired list while only establishing one live BLE connection, so WhiskerLink currently keeps the simpler single-probe model.

## PT tables have finite ranges

If a pressure falls outside the available pressure/temperature table, WhiskerLink leaves the saturation value blank rather than extrapolating beyond the table.
