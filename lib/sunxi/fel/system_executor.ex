defmodule Sunxi.FEL.SystemExecutor do
  @moduledoc """
  Implementation of Sunxi.FEL.Executor using System.cmd/3.
  """
  @behaviour Sunxi.FEL.Executor

  @impl true
  def cmd(path, args, opts), do: System.cmd(path, args, opts)
end
