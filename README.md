# Sunxi

Sunxi is an Elixir package that provides bindings to the `sunxi-tools` C
library. It allows for interaction with Allwinner devices connected via USB in
FEL mode. The package vendors the `sunxi-tools` source code and compiles it as
part of the Elixir build process.

## Vendoring

This project vendors the `sunxi-tools` source code. It uses a fork located at
[gworkman/sunxi-tools](https://github.com/gworkman/sunxi-tools) which includes
support for progress reporting during SPL transfers (a feature currently pending
in a PR to the main repository).

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
[
  %Sunxi.Device{
    device: "026",
    bus: "020",
    model: "R528",
    sid: "93407200:7c004814:0102a04c:5c5b1cd8"
  }
]
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

### Target Specific Device

When multiple devices are connected, you can specify which one to target using
the `:device` option:

```elixir
[device | _] = Sunxi.FEL.list_devices()
Sunxi.FEL.read_memory(0x20000, 4, device: device)
```

### Progress Reporting

Functions that transfer data (`write_memory/3`, `execute_spl/2`,
`execute_uboot/2`) support an `:on_progress` callback:

```elixir
Sunxi.FEL.execute_uboot("u-boot.bin", on_progress: fn progress ->
  IO.inspect(progress)
  # %{percentage: 45, speed: 150.2, eta: "0:02"}
end)
```

If no devices are connected, you get an error:

```elixir
iex> Sunxi.FEL.write_memory(address, <<0x01, 0x02, 0x03, 0x04>>)
{:error, :no_device_connected}
```

Other errors will be strings.
