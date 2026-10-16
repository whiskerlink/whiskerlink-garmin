#!/usr/bin/env bash

# User-local helper binaries.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Discover the current Garmin SDK selected by connect-iq-sdk-manager.
if command -v connect-iq-sdk-manager >/dev/null 2>&1; then
    CIQ_BIN="$(connect-iq-sdk-manager sdk current-path --bin 2>/dev/null || true)"

    if [ -n "$CIQ_BIN" ] && [ -d "$CIQ_BIN" ]; then
        export CIQ_SDK="$(dirname "$CIQ_BIN")"

        case ":$PATH:" in
            *":$CIQ_BIN:"*) ;;
            *) export PATH="$CIQ_BIN:$PATH" ;;
        esac
    fi
fi

if [ -z "${DEV_KEY:-}" ]; then
    export DEV_KEY="$PWD/.secrets/developer_key"
fi

export CIQ_DEVICE="${CIQ_DEVICE:-instinct2}"
