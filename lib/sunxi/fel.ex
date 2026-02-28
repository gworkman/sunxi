defmodule Sunxi.FEL do
  @moduledoc """
  An Elixir wrapper for the `sunxi-fel` utility.
  """

  @binary_name "sunxi-fel"

  @doc """
  Lists connected Allwinner devices in FEL mode.
  """
  @spec list_devices() :: {:ok, [map()]} | {:error, any()}
  def list_devices do
    case exec(["--list"]) do
      {:ok, output} ->
        {:ok, parse_list(output)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Writes data to the device's memory at the specified address.
  """
  @spec write_memory(non_neg_integer(), binary()) :: :ok | {:error, any()}
  def write_memory(address, data) do
    with {:ok, temp_file} <- create_temp_file(data),
         {:ok, _} <- exec(["write", format_address(address), temp_file]) do
      File.rm(temp_file)
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Reads data from the device's memory at the specified address.
  """
  @spec read_memory(non_neg_integer(), non_neg_integer()) :: {:ok, binary()} | {:error, any()}
  def read_memory(address, size) do
    # Using 'read' instead of 'dump' because 'dump' outputs to stdout
    # and might be affected by terminal settings or encoding.
    # 'read <address> <length> <file>' is more explicit.
    temp_file = Path.join(System.tmp_dir!(), "sunxi_read_#{:erlang.unique_integer([:positive])}")

    case exec(["read", format_address(address), to_string(size), temp_file]) do
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
  """
  @spec execute_spl(String.t()) :: :ok | {:error, any()}
  def execute_spl(path) do
    case exec(["spl", path]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Loads and executes U-Boot.
  """
  @spec execute_uboot(String.t()) :: :ok | {:error, any()}
  def execute_uboot(path) do
    case exec(["uboot", path]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Internal Helpers ---

  defp exec(args, opts \\ []) do
    executor = get_executor()
    binary_path = get_binary_path()

    if executor == Sunxi.FEL.SystemExecutor do
      run_port(binary_path, args, opts)
    else
      # Fallback for MockExecutor in tests
      case executor.cmd(binary_path, args, stderr_to_stdout: true) do
        {output, 0} ->
          {:ok, output}

        {output, status} ->
          {:error, "Command failed with exit code #{status}: #{String.trim(output)}"}
      end
    end
  end

  defp run_port(binary_path, args, _opts) do
    port =
      Port.open({:spawn_executable, binary_path}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: args
      ])

    collect_output(port, "")
  end

  defp collect_output(port, acc) do
    receive do
      {^port, {:data, data}} ->
        collect_output(port, acc <> data)

      {^port, {:exit_status, 0}} ->
        {:ok, acc}

      {^port, {:exit_status, status}} ->
        {:error, "Command failed with exit code #{status}: #{String.trim(acc)}"}
    end
  end

  defp get_executor do
    Application.get_env(:sunxi, :executor, Sunxi.FEL.SystemExecutor)
  end

  defp get_binary_path do
    Application.app_dir(:sunxi, Path.join("priv", "bin/#{@binary_name}"))
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
          %{bus: bus, device: device, model: model, sid: sid}

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp create_temp_file(data) do
    path = Path.join(System.tmp_dir!(), "sunxi_write_#{:erlang.unique_integer([:positive])}")

    case File.write(path, data) do
      :ok -> {:ok, path}
      error -> error
    end
  end
end
