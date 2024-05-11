defmodule Minikv.Kv do
  @enforce_keys [:value]

  @type lock() :: boolean()

  @type t :: %__MODULE__{
          value: any(),
          node: node(),
          time: integer(),
          exp: integer() | nil,
          lock: lock() | nil
        }
  defstruct [:value, :node, :time, :exp, :lock]
end
