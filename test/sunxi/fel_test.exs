defmodule Sunxi.FELTest do
  use ExUnit.Case, async: false

  alias Sunxi.FEL

  @moduletag :no_device

  describe "when no device is connected" do
    test "list_devices/0 returns empty list" do
      assert {:ok, []} == FEL.list_devices()
    end

    test "write_memory/2 returns error" do
      assert {:error, :no_device_connected} ==
               FEL.write_memory(0x20000, <<1, 2, 3, 4>>)
    end

    test "read_memory/2 returns error" do
      assert {:error, :no_device_connected} ==
               FEL.read_memory(0x20000, 4)
    end

    test "execute_spl/1 returns error" do
      assert {:error, :no_device_connected} ==
               FEL.execute_spl("non_existent_file.bin")
    end

    test "execute_uboot/1 returns error" do
      assert {:error, :no_device_connected} ==
               FEL.execute_uboot("non_existent_file.bin")
    end
  end
end
