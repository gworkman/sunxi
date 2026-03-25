defmodule Sunxi.FELIntegrationTest do
  use ExUnit.Case, async: false

  alias Sunxi.FEL

  @moduletag :device_connected

  test "list_devices/0 returns connected devices" do
    case FEL.list_devices() do
      {:ok, [_ | _] = devices} ->
        IO.puts("\nFound #{length(devices)} FEL device(s)")
        Enum.each(devices, fn d -> IO.inspect(d) end)

      {:ok, []} ->
        flunk("No FEL devices found. Ensure your device is in FEL mode.")

      {:error, reason} ->
        flunk("Failed to list devices: #{reason}")
    end
  end

  test "read and write memory with device option" do
    # SRAM A1 address for T113-S3
    address = 0x20000
    data = <<0xBE, 0xEF, 0xCA, 0xFE>>

    {:ok, [device | _]} = FEL.list_devices()

    assert :ok = FEL.write_memory(address, data, device: device)
    assert {:ok, ^data} = FEL.read_memory(address, 4, device: device)
  end
end
