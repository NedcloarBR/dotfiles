#!/usr/bin/env bash
#
# Rewrites Bash commands to their `rtk` equivalent so Claude reads compressed output.
# No-op when rtk isn't installed, so the config stays portable across machines.

rtk=$(command -v rtk || echo "$HOME/.local/bin/rtk")
[[ -x "$rtk" ]] || exit 0

exec "$rtk" hook claude
