defmodule Sunxi.FELIntegrationTest do
  use ExUnit.Case, async: false

  alias Sunxi.FEL

  @moduletag :integration

  setup do
    # Temporarily restore SystemExecutor for integration tests
    Application.put_env(:sunxi, :executor, Sunxi.FEL.SystemExecutor)

    on_exit(fn ->
      # Restore MockExecutor
      Application.put_env(:sunxi, :executor, Sunxi.FEL.MockExecutor)
    end)

    :ok
  end

  test "list_devices/0 returns connected devices" do
    case FEL.list_devices() do
      {:ok, devices} when is_list(devices) ->
        IO.puts("
Found #{length(devices)} FEL device(s)")
        Enum.each(devices, fn d -> IO.inspect(d) end)

      {:error, reason} ->
        flunk("Failed to list devices: #{reason}")
    end
  end

  test "read and write memory" do
    # SRAM A1 address for R528/T113-S3 (and many newer Allwinner SoCs)
    address = 0x20000
    data = <<0xDE, 0xAD, 0xBE, 0xEF>>

    assert :ok = FEL.write_memory(address, data)
    assert {:ok, ^data} = FEL.read_memory(address, 4)
  end
end
