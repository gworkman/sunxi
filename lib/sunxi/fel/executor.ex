defmodule Sunxi.FEL.Executor do
  @moduledoc """
  Behavior for executing sunxi-fel commands.
  """
  @callback cmd(String.t(), [String.t()], keyword()) :: {binary(), integer()}
end
