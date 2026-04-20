# MFM-CSI-ADVANCED
the whole CSI folder made by MFM

## Development environment (Cursor Cloud / Linux)

This repository is a REAPER CSI package, so there is no standalone web server to launch.
The runnable component in this environment is the Lua engine script via a mocked REAPER API smoke test.

### 1) Setup

Run:

`./scripts/setup_dev_env.sh`

This installs (or validates) a Lua interpreter.

### 2) Run application smoke test

Run:

`./scripts/run_application_smoke.sh`

Expected output includes:

`Smoke test passed: engine loop updated selected items via mocked REAPER API.`

## REAPER placement notes

- `\`JSCSI_ItemShape.jsfx\`` belongs in REAPER Effects.
- `\`mfm_csi_itemshape_engine.lua` belongs in REAPER Scripts.
