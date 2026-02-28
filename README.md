# Sunxi

Sunxi is an Elixir package that provides bindings to the `sunxi-tools` C
library. It allows for interaction with Allwinner devices connected via USB in
FEL mode. The package vendors the `sunxi-tools` source code and compiles it as
part of the Elixir build process.

## Vendoring

This project vendors the `sunxi-tools` source code (git commit hash
`7540cb235691be94ac5ef0181a73dd929949fc4e`) from the
[linux-sunxi/sunxi-tools](https://github.com/linux-sunxi/sunxi-tools)
repository.

## Dependencies

The `sunxi-tools` library requires several development libraries to be installed
on the host system.

On macOS, these can be installed with the following command:

```bash
brew install libusb dtc zlib pkg-config
```

On Ubuntu or Debian, these can be installed with the following command:

```bash
sudo apt-get install libusb-1.0-0-dev libfdt-dev zlib1g-dev pkg-config
```

For Windows, WSL may be required to run use this package.

## Usage

The `Sunxi.FEL` module provides functions to interact with devices in FEL mode.

To list connected Allwinner devices:

```elixir
Sunxi.FEL.list_devices()
```

To read and write memory:

```elixir
Sunxi.FEL.write_memory(address, binary_data)
Sunxi.FEL.read_memory(address, length)
```

To load and execute bootloaders (for U-Boot, if the U-Boot and SPL file are
packaged together):

```elixir
Sunxi.FEL.execute_spl("path/to/spl.bin")
Sunxi.FEL.execute_uboot("path/to/u-boot.bin")
```
