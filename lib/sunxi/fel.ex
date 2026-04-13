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
    * `:on_progress` - A callback function that receives progress updates.
      The callback receives a map: `%{percentage: integer, speed: float, eta: String.t | nil}`.
      `speed` is in kB/s.
  """
  @spec write_memory(non_neg_integer(), binary(), keyword()) :: :ok | {:error, any()}
  def write_memory(address, data, opts \\ []) do
    with {:ok, temp_file} <- create_temp_file(data),
         {:ok, _} <- exec(["-p", "write", format_address(address), temp_file], opts) do
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
  Loads and executes a U-Boot SPL image.

  If the file additionally contains a main U-Boot binary (e.g., `u-boot-sunxi-with-spl.bin`),
  this command also transfers that to memory (at the default address from the image),
  but won't execute it.

  ## Options

    * `:device` - A `Sunxi.Device` struct representing the target device.
    * `:on_progress` - A callback function that receives progress updates.
      The callback receives a map: `%{percentage: integer, speed: float, eta: String.t | nil}`.
      `speed` is in kB/s.
  """
  @spec execute_spl(String.t(), keyword()) :: :ok | {:error, any()}
  def execute_spl(path, opts \\ []) do
    case exec(["-p", "spl", path], opts) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Loads and executes U-Boot.

  This is similar to `execute_spl/2`, but actually starts U-Boot execution
  when the `sunxi-fel` utility exits.

  ## Options

    * `:device` - A `Sunxi.Device` struct representing the target device.
    * `:on_progress` - A callback function that receives progress updates.
      The callback receives a map: `%{percentage: integer, speed: float, eta: String.t | nil}`.
      `speed` is in kB/s.
  """
  @spec execute_uboot(String.t(), keyword()) :: :ok | {:error, any()}
  def execute_uboot(path, opts \\ []) do
    case exec(["-p", "uboot", path], opts) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Internal Helpers ---

  defp exec(args, opts \\ []) do
    binary_path = get_binary_path()
    args = build_args(args, opts)

    port =
      Port.open({:spawn_executable, binary_path}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: args
      ])

    collect_port_output(port, "", "", opts)
  end

  defp collect_port_output(port, buffer, output_acc, opts) do
    receive do
      {^port, {:data, data}} ->
        {new_buffer, new_output_acc} = process_data(buffer <> data, output_acc, opts)
        collect_port_output(port, new_buffer, new_output_acc, opts)

      {^port, {:exit_status, 0}} ->
        {_new_buffer, new_output_acc} = process_data(buffer, output_acc, opts, true)
        {:ok, new_output_acc}

      {^port, {:exit_status, 1}} ->
        {_new_buffer, new_output_acc} = process_data(buffer, output_acc, opts, true)

        if String.contains?(new_output_acc, "ERROR: Allwinner USB FEL device not found!") do
          {:error, :no_device_connected}
        else
          {:error, new_output_acc}
        end

      {^port, {:exit_status, _status}} ->
        {_new_buffer, new_output_acc} = process_data(buffer, output_acc, opts, true)
        {:error, new_output_acc}
    end
  end

  defp process_data(data, output_acc, opts, final? \\ false) do
    case find_last_delimiter(data) do
      nil ->
        if final? and data != "" do
          {_segments, new_output_acc} = process_segments([data], output_acc, opts)
          {"", new_output_acc}
        else
          {data, output_acc}
        end

      index ->
        {to_process, rest} = String.split_at(data, index + 1)

        segments =
          to_process
          |> String.split(~r/\r|\n/, trim: true)
          |> Enum.reject(&(&1 == ""))

        {_, new_output_acc} = process_segments(segments, output_acc, opts)

        if final? and rest != "" do
          {_, final_output_acc} = process_segments([rest], new_output_acc, opts)
          {"", final_output_acc}
        else
          {rest, new_output_acc}
        end
    end
  end

  defp process_segments(segments, output_acc, opts) do
    new_output_acc =
      Enum.reduce(segments, output_acc, fn segment, acc ->
        case parse_progress(segment) do
          {:ok, progress} ->
            if callback = opts[:on_progress], do: callback.(progress)
            acc

          :error ->
            acc <> segment <> "\n"
        end
      end)

    {segments, new_output_acc}
  end

  defp find_last_delimiter(data) do
    case :binary.match(data, ["\r", "\n"], [{:scope, {byte_size(data), -byte_size(data)}}]) do
      {index, 1} -> index
      :nomatch -> nil
    end
  end

  defp parse_progress(line) do
    # 1: percentage, 2: speed (ETA case), 3: ETA, 4: speed (Done case)
    regex =
      ~r/^\s*(\d+)%\s+\[(?:[=\s]+)\]\s+(?:([\d\.]+)\s+kB\/s,\s+ETA\s+([\d:]+)|[\d\.]+\s+kB,\s+([\d\.]+)\s+kB\/s)\s*$/

    case Regex.run(regex, String.trim_trailing(line)) do
      [_, percentage, speed_eta, eta] ->
        {:ok,
         %{
           percentage: String.to_integer(percentage),
           speed: parse_float(speed_eta),
           eta: String.trim(eta)
         }}

      [_, percentage, "", "", speed_done] ->
        {:ok,
         %{
           percentage: String.to_integer(percentage),
           speed: parse_float(speed_done),
           eta: nil
         }}

      _ ->
        :error
    end
  end

  defp parse_float(str) do
    str = String.trim(str)

    case Float.parse(str) do
      {f, _} -> f
      :error -> 0.0
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
