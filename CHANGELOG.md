# Changelog

## v0.1.4 (2026-03-25)

- Improve docs
- Fix broken tests

## v0.1.3 (2026-03-25)

- Created a `%Sunxi.Device{}` struct
- `Sunxi.FEL.list_devices/0` now returns a list of devices (or empty list), not
  `{:ok, devices}`
- Device-specific `Sunxi.FEL` functions now accept keyword opts, particularly
  the `device: %Sunxi.Device{}` option

## v0.1.2 (2026-03-22)

- Allow sunxi-fel binary path to be configured in Application env (useful for
  escripts)

## v0.1.1 (2026-03-22)

- Fix how the sunxi-fel binary path is loaded at runtime

## v0.1.0 (2026-02-28)

- Initial release.
- Vendored `sunxi-tools` (commit `7540cb2`).
- Implemented `Sunxi.FEL` wrapper for memory operations and code execution.
- Added support for list devices, read/write memory, SPL execution, and U-Boot
  execution.
- Configured `elixir_make` with automatic dependency checks.
