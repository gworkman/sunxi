defmodule Sunxi.FEL do
  @moduledoc """
  An Elixir wrapper for the `sunxi-fel` utility.
  """

  alias Sunxi.Device

  @binary_name "sunxi-fel"

  @doc """
  Lists connected Allwinner devices in FEL mode.
  """
  @spec list_devices() :: [Device.t()] | {:error, any()}
  def list_devices do
    case exec(["--list"]) do
      {:ok, output} ->
        parse_list(output)

      {:error, output} when output in ["", "\n"] ->
        []

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Writes data to the device's memory at the specified address.

  ## Options

    * `:device` - A `Sunxi.Device` struct representing the target device.
  """
  @spec write_memory(non_neg_integer(), binary(), keyword()) :: :ok | {:error, any()}
  def write_memory(address, data, opts \\ []) do
    with {:ok, temp_file} <- create_temp_file(data),
         {:ok, _} <- exec(["write", format_address(address), temp_file], opts) do
      File.rm(temp_file)
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Reads data from the device's memory at the specified address.

  ## Options

    * `:device` - A `Sunxi.Device` struct representing the target device.
  """
  @spec read_memory(non_neg_integer(), non_neg_integer(), keyword()) ::
          {:ok, binary()} | {:error, any()}
  def read_memory(address, size, opts \\ []) do
    temp_file = create_temp_path()

    case exec(["read", format_address(address), to_string(size), temp_file], opts) do
      {:ok, _} ->
        data = File.read!(temp_file)
        File.rm(temp_file)
        {:ok, data}

      {:error, reason} ->
        File.rm(temp_file)
        {:error, reason}
    end
  end

  @doc """
  Loads and executes an SPL image.

  ## Options

    * `:device` - A `Sunxi.Device` struct representing the target device.
  """
  @spec execute_spl(String.t(), keyword()) :: :ok | {:error, any()}
  def execute_spl(path, opts \\ []) do
    case exec(["spl", path], opts) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Loads and executes U-Boot.

  ## Options

    * `:device` - A `Sunxi.Device` struct representing the target device.
  """
  @spec execute_uboot(String.t(), keyword()) :: :ok | {:error, any()}
  def execute_uboot(path, opts \\ []) do
    case exec(["uboot", path], opts) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Internal Helpers ---

  defp exec(args, opts \\ []) do
    binary_path = get_binary_path()
    args = build_args(args, opts)

    case System.cmd(binary_path, args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {"ERROR: Allwinner USB FEL device not found!\n", 1} ->
        {:error, :no_device_connected}

      {output, _status} ->
        {:error, output}
    end
  end

  defp build_args(args, opts) do
    case opts[:device] do
      %Device{sid: sid} when is_binary(sid) ->
        ["--sid", sid | args]

      _ ->
        args
    end
  end

  defp get_binary_path do
    default_bin_path =
      :sunxi
      |> :code.priv_dir()
      |> Path.join("bin/#{@binary_name}")

    Application.get_env(:sunxi, :sunxi_fel_path) || default_bin_path
  end

  defp format_address(address) do
    "0x#{Integer.to_string(address, 16)}"
  end

  defp parse_list(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case Regex.run(~r/USB device (\d+):(\d+)\s+Allwinner\s+([^\s]+)\s+([0-9a-fA-F:]+)/, line) do
        [_, bus, device, model, sid] ->
          %Device{bus: bus, device: device, model: model, sid: sid}

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp create_temp_file(data) do
    path = create_temp_path()

    case File.write(path, data) do
      :ok -> {:ok, path}
      error -> error
    end
  end

  defp create_temp_path do
    Path.join(System.tmp_dir!(), "sunxi_#{:erlang.unique_integer([:positive])}")
  end
end
