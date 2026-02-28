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

  test "read and write memory" do
    # SRAM A1 address for R528/T113-S3
    address = 0x20000
    data = <<0xDE, 0xAD, 0xBE, 0xEF>>

    assert :ok = FEL.write_memory(address, data)
    assert {:ok, ^data} = FEL.read_memory(address, 4)
  end
end
