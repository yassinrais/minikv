defmodule Minikv.Kv do
  @enforce_keys [:val]
  defstruct [:val, :node, :time]
end
