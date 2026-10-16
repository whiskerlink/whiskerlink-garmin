# garmin-connect-template

A NixOS-friendly Garmin Connect IQ / Monkey C starter project.

This template targets the **Garmin Instinct 2 / Solar** and builds a tiny
`Hello Wrist` watch app.

It intentionally avoids Garmin's GUI SDK Manager. On NixOS the GUI's old
GTK/WebKit dependencies are unnecessarily painful. Instead this template uses
the community `connect-iq-sdk-manager` CLI.

## 1. Enter the development shell

```bash
nix develop
```

## 2. Install the SDK manager CLI

```bash
./scripts/install-sdk-manager-cli
```

This installs:

```text
~/.local/bin/connect-iq-sdk-manager
```

and creates Garmin's expected SDK directory:

```text
~/.Garmin/ConnectIQ/Sdks
```

Re-enter the shell:

```bash
exit
nix develop
```

## 3. Install/select the Garmin SDK

Read Garmin's agreement:

```bash
connect-iq-sdk-manager agreement view
```

If you accept it:

```bash
connect-iq-sdk-manager agreement accept
connect-iq-sdk-manager login
```

List SDKs:

```bash
connect-iq-sdk-manager sdk list
```

Select/install one, for example:

```bash
connect-iq-sdk-manager sdk set 9.2.0
```

Download device support referenced by `manifest.xml`:

```bash
connect-iq-sdk-manager device download \
  --manifest=manifest.xml \
  --include-fonts
```

Then:

```bash
exit
nix develop
```

## 4. Patch Garmin's launcher scripts for NixOS

Garmin's Linux SDK uses `#!/bin/bash`, but NixOS does not provide `/bin/bash`.

Run once per newly installed SDK:

```bash
./scripts/patch-sdk
```

## 5. Generate a developer key

```bash
./scripts/generate-key
```

The key is stored under `.secrets/` and ignored by Git.

Back it up somewhere safe.

## 6. Check the environment

```bash
./scripts/check
```

You want Java, the SDK manager, `monkeyc`, `monkeydo`, `simulator`, and the
developer key all present.

## 7. Build

```bash
./scripts/build
```

Output:

```text
bin/GarminConnectTemplate.prg
```

## 8. Sideload

Connect the watch, choose **Use Mass Storage? → Yes**, and copy:

```text
bin/GarminConnectTemplate.prg
```

to:

```text
GARMIN/APPS/
```

Then eject/disconnect the watch and launch **Garmin Connect Template**.

## Template details

- Device target: `instinct2`
- Minimum Connect IQ API: `3.4.0`
- Launcher icon: 62×62, matching Instinct 2
- `BluetoothLowEnergy` permission is already enabled
- SDK binaries and device data stay outside the Git repository
- `flake.lock` should be committed after the first `nix develop`
