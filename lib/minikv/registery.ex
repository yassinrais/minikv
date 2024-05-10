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
    name = Keyword.get(opts, :name) || raise ArgumentError, "Name is required for a registery"

    send(self(), :initiated)
    {:ok, %{table: name, opts: opts}}
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
      iex> Minikv.Registry.delete(registry, "my_key")
      :ok
  """
  @spec delete(atom(), binary()) :: result()
  def delete(server, key) do
    GenServer.call(server, {:del, key})
  end

  def handle_call({_op, nil}, _from, state),
    do: {:reply, {:invalid_key, "nil is not valid keyname"}, state}

  def handle_call({_op, nil, _val}, _from, state),
    do: {:reply, {:invalid_key, "nil is not valid keyname"}, state}

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
      node: node(),
      time: current_nano_time()
    }

    exec_op(table, :put, {key, kv})

    {:reply, kv, state}
  end

  def handle_call({:del, key}, _from, %{table: table} = state) do
    case :ets.lookup(table, key) do
      [{^key, %Kv{} = kv}] ->
        exec_op(table, :del, {key, kv})
        {:reply, kv, state}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_call({:ask_sync}, _from, %{table: table} = state) do
    exec_op(table, :ask_sync, {nil, nil})
    {:reply, nil, state}
  end

  def handle_cast({table, :sync, target_node, _}, state) do
    self_node = node()

    case target_node do
      ^self_node ->
        :noop

      _ ->
        GenServer.cast({table, target_node}, {table, :put_bulk, :ets.tab2list(table)})
    end

    {:noreply, state}
  end

  def handle_cast({table, :put, key, kv}, state) do
    true = :ets.insert(table, {key, kv})
    {:noreply, state}
  end

  def handle_cast({table, :put_bulk, kvs}, state) do
    true = :ets.insert(table, kvs)
    {:noreply, state}
  end

  def handle_cast({table, :del, key, _}, state) do
    true = :ets.delete(table, key)
    {:noreply, state}
  end

  def handle_info(:initiated, %{table: table} = state) do
    exec_op(table, :sync, {node(), nil})

    {:noreply, state}
  end

  def handle_info({:nodedown, down_node}, %{table: table} = state) do
    self_node = node()

    with nodes <- Enum.sort([self_node] ++ Node.list()),
         next_node_owner <- hd(nodes),
         ^self_node <- next_node_owner,
         kvs <- :ets.tab2list(table) |> Enum.filter(fn {_k, val} -> val.node == down_node end),
         true <- length(kvs) > 0 do
      kvs =
        Enum.map(kvs, fn {k, v} ->
          {k, Map.merge(v, %{node: next_node_owner})}
        end)

      exec_op(table, :put_bulk, {kvs})
    end

    {:noreply, state}
  end

  def handle_info({:nodeup, _node}, state) do
    {:noreply, state}
  end

  defp exec_op(table, op, state) do
    nodes = [node()] ++ Node.list()

    [:ok | _] =
      nodes
      |> Enum.map(fn target_node ->
        emit_state = List.to_tuple(Tuple.to_list({table, op}) ++ Tuple.to_list(state))
        GenServer.cast({table, target_node}, emit_state)
      end)
  end

  defp current_nano_time() do
    System.system_time(:nanosecond)
  end
end
