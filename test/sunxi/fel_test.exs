defmodule Sunxi.FELTest do
  use ExUnit.Case, async: true
  import Mox

  alias Sunxi.FEL

  setup :verify_on_exit!

  describe "list_devices/0" do
    test "returns a list of connected devices" do
      output = "USB device 001:005   Allwinner A20 12345678:9abcdef0:12345678:9abcdef0\n"

      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path, ["--list"], _opts ->
        {output, 0}
      end)

      assert {:ok, [device]} = FEL.list_devices()
      assert device.bus == "001"
      assert device.device == "005"
      assert device.model == "A20"
      assert device.sid == "12345678:9abcdef0:12345678:9abcdef0"
    end

    test "returns an empty list when no devices are found" do
      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path, ["--list"], _opts ->
        {"", 0}
      end)

      assert {:ok, []} == FEL.list_devices()
    end

    test "returns an error when the command fails" do
      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path, ["--list"], _opts ->
        {"Error: libusb_open failed\n", 1}
      end)

      assert {:error, "Command failed with exit code 1: Error: libusb_open failed"} ==
               FEL.list_devices()
    end
  end

  describe "write_memory/2" do
    test "writes binary data to the specified address using a temp file" do
      address = 0x40000000
      data = <<1, 2, 3, 4>>

      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path, ["write", "0x40000000", temp_file], _opts ->
        assert String.contains?(temp_file, "sunxi_write_")
        # Verify that the temp file was actually written
        assert File.read!(temp_file) == data
        {"", 0}
      end)

      assert :ok == FEL.write_memory(address, data)
    end
  end

  describe "read_memory/2" do
    test "reads binary data from the specified address using a temp file" do
      address = 0x40000000
      size = 4
      data = <<1, 2, 3, 4>>

      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path,
                                              ["read", "0x40000000", "4", temp_file],
                                              _opts ->
        assert String.contains?(temp_file, "sunxi_read_")
        # Simulate sunxi-fel writing to the file
        File.write!(temp_file, data)
        {"", 0}
      end)

      assert {:ok, ^data} = FEL.read_memory(address, size)
    end
  end

  describe "execute_spl/1" do
    test "executes SPL from a file" do
      path = "path/to/spl.bin"

      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path, ["spl", ^path], _opts ->
        {"", 0}
      end)

      assert :ok == FEL.execute_spl(path)
    end
  end

  describe "execute_uboot/1" do
    test "executes U-Boot from a file" do
      path = "path/to/uboot.bin"

      expect(Sunxi.FEL.MockExecutor, :cmd, fn _path, ["uboot", ^path], _opts ->
        {"", 0}
      end)

      assert :ok == FEL.execute_uboot(path)
    end
  end
end
