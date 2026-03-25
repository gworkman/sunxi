defmodule Sunxi.Device do
  @moduledoc """
  Represents a connected Allwinner device in FEL mode.
  """

  defstruct [:bus, :device, :model, :sid]

  @type t :: %__MODULE__{
          bus: String.t(),
          device: String.t(),
          model: String.t(),
          sid: String.t()
        }
end
