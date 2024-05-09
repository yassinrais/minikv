defmodule Minikv.Registry do
  @moduledoc """
  A registry for Minikv, providing a distributed key-value store.
  """
  use GenServer
  alias Minikv.Kv

  @type result() :: nil | %Kv{}

  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    :net_kernel.monitor_nodes(true)
    {:ok, %{table: opts[:name], opts: opts}}
  end

  @doc """
  Retrieves a value from the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Registry.start_link(name: :my_registry)
      iex> Minikv.Registry.get(registry, "my_key")
      %Minikv.Kv{val: "my_value", node: :node1, time: 123456789}
  """
  @spec get(atom(), binary()) :: result()
  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @doc """
  Puts a value into the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Registry.start_link(name: :my_registry)
      iex> Minikv.Registry.put(registry, "my_key", "my_value")
      :ok
  """
  @spec put(atom(), binary(), any()) :: result()
  def put(server, key, value) do
    GenServer.call(server, {:put, key, value})
  end

  @doc """
  Deletes a value from the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Registry.start_link(name: :my_registry)
      iex> Minikv.Registry.del(registry, "my_key")
      :ok
  """
  @spec del(atom(), binary()) :: result()
  def del(server, key) do
    GenServer.call(server, {:del, key})
  end

  def handle_call({_op, nil}, _from, state),
    do: {:reply, {:kv_invalid_key, "nil is not valid keyname"}, state}

  def handle_call({_op, nil, _val}, _from, state),
    do: {:reply, {:kv_invalid_key, "nil is not valid keyname"}, state}

  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(state.table, key) do
      [{^key, %Kv{} = kv}] ->
        {:reply, kv, state}

      [] ->
        {:reply, nil, state}
    end
  end

  def handle_call({:put, key, val}, _from, %{table: table} = state) do
    kv = %Kv{
      val: val,
      node: Node.self(),
      time: current_nano_time()
    }

    {:reply, exec_op(table, {:put, key, kv}), state}
  end

  def handle_call({:del, key}, _from, %{table: table} = state) do
    case :ets.lookup(table, key) do
      [{^key, %Kv{} = kv}] ->
        {:reply, exec_op(table, {:del, key, kv}), state}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_cast({table, :put, key, kv}, state) do
    true = :ets.insert(table, {key, kv})
    {:noreply, state}
  end

  def handle_cast({table, :del, key, _}, state) do
    true = :ets.delete(table, key)
    {:noreply, state}
  end

  def handle_info({:nodedown, _node}, state) do
    {:noreply, state}
  end

  def handle_info({:nodeup, _node}, state) do
    {:noreply, state}
  end

  defp exec_op(table, {op, key, kv}) do
    [:ok | _] =
      Enum.map([Node.self() | Node.list()], fn target_node ->
        GenServer.cast({table, target_node}, {table, op, key, kv})
      end)

    kv
  end

  defp current_nano_time() do
    System.system_time(:nanosecond)
  end
end
