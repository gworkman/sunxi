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

For Windows, WSL may be required to use this package.

## Usage

The `Sunxi.FEL` module provides functions to interact with devices in FEL mode.

To list connected Allwinner devices:

```elixir
iex> Sunxi.FEL.list_devices()
{:ok,
 [
   %{
     device: "026",
     bus: "020",
     model: "R528",
     sid: "93407200:7c004814:0102a04c:5c5b1cd8"
   }
 ]}
```

To read and write memory when a device is connected:

```elixir
iex> address = 0x20000

iex> Sunxi.FEL.write_memory(address, <<0x01, 0x02, 0x03, 0x04>>)
:ok

iex> Sunxi.FEL.read_memory(address, 4)
{:ok, <<1, 2, 3, 4>>}
```

To load and execute bootloaders (for U-Boot, if the U-Boot and SPL file are
packaged together into one file, it will properly load both at the same time):

```elixir
Sunxi.FEL.execute_spl("path/to/spl.bin")
Sunxi.FEL.execute_uboot("path/to/u-boot.bin")
```

If no devices are connected, you get an error:

```elixir
iex> Sunxi.FEL.write_memory(address, <<0x01, 0x02, 0x03, 0x04>>)
{:error, :no_device_connected}
```

Other errors will be strings.
