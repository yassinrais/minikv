defmodule Minikv.Registry do
  @moduledoc """
  A registry for Minikv, providing a distributed key-value store.
  """
  use GenServer
  alias Minikv.Kv

  @type lock() :: Kv.lock()
  @type kv() :: Kv.t()
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
      %Minikv.Kv{value: "my_value", node: :node1, time: 123456789}
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
  @spec put(atom(), binary(), kv() | any()) :: result()
  def put(server, key, opts) when is_list(opts) do
    GenServer.call(server, {:put, key, opts})
  end

  def put(server, key, value) do
    GenServer.call(server, {:put, key, value: value})
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

  @doc """
  Persist a key value in the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Registry.start_link(name: :my_registry)
      iex> Minikv.Registry.delete(registry, "my_key")
      :ok
  """
  @spec persist(atom(), binary()) :: result()
  def persist(server, key) do
    GenServer.call(server, {:persist, key})
  end

  @doc """
  Lock a key in the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Registry.start_link(name: :my_registry)
      iex> Minikv.Registry.lock(registry, "my_key")
      :ok
  """
  @spec lock(atom(), binary()) :: result()
  def lock(server, key) do
    GenServer.call(server, {:lock, key})
  end

  @doc """
  Unlock a key in the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Registry.start_link(name: :my_registry)
      iex> Minikv.Registry.lock(registry, "my_key")
      :ok
      iex> Minikv.Registry.unlock(registry, "my_key")
      :ok
  """
  @spec unlock(atom(), binary()) :: result()
  def unlock(server, key) do
    GenServer.call(server, {:unlock, key})
  end

  def handle_call({_op, nil}, _from, state),
    do: {:reply, {:invalid_key, "nil is not valid keyname"}, state}

  def handle_call({_op, nil, _val}, _from, state),
    do: {:reply, {:invalid_key, "nil is not valid keyname"}, state}

  def handle_call({:get, key}, _from, %{table: table} = state) do
    case lookup_key(table, key) do
      {:ok, %Kv{exp: exp} = kv} ->
        if exp != nil and exp <= current_nano_time() do
          # expire key
          exec_op(table, :del, {key, kv})
          {:reply, nil, state}
        else
          {:reply, kv, state}
        end

      {:error, :not_found} ->
        {:reply, nil, state}
    end
  end

  def handle_call({:put, key, opts}, _from, %{table: table, opts: default_opts} = state) do
    node = node()

    value = Keyword.get(opts, :value)
    ttl = Keyword.get(opts, :ttl)
    lock = Keyword.get(opts, :lock)
    persist = Keyword.get(opts, :persist)

    case lookup_key(table, key) do
      {:ok, %Kv{lock: true, node: node_owner}} when node_owner != node ->
        {:reply, {:error, :locked}, state}

      other ->
        kv =
          generate_kv(
            node,
            value,
            ttl || default_opts[:default_ttl],
            lock,
            persist
          )

        case other do
          {:ok, %Kv{}} ->
            exec_op(table, :put, {key, kv})
            {:reply, kv, state}

          {:error, :not_found} ->
            exec_op(table, :put, {key, kv})
            {:reply, kv, state}
        end
    end
  end

  def handle_call({:del, key}, _from, %{table: table} = state) do
    case lookup_key(table, key) do
      {:ok, %Kv{} = kv} ->
        exec_op(table, :del, {key, kv})
        {:reply, kv, state}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_call({:persist, key}, _from, %{table: table} = state) do
    case lookup_key(table, key) do
      {:ok, %Kv{lock: true, node: node_owner}} when node_owner != node() ->
        {:reply, {:error, :locked}, state}

      {:ok, %Kv{} = kv} ->
        kv = struct(kv, exp: nil)

        exec_op(table, :put, {key, kv})
        {:reply, kv, state}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_call({:lock, key}, _from, %{table: table} = state) do
    case lookup_key(table, key) do
      {:ok, %Kv{lock: true, node: node_owner}} when node_owner != node() ->
        {:reply, {:error, :locked}, state}

      {:ok, %Kv{} = kv} ->
        kv = struct(kv, lock: true)
        exec_op(table, :put, {key, kv})
        {:reply, kv, state}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_call({:unlock, key}, _from, %{table: table} = state) do
    case lookup_key(table, key) do
      {:ok, %Kv{lock: true, node: node_owner}} when node_owner != node() ->
        {:reply, {:error, :locked}, state}

      {:ok, %Kv{lock: nil} = kv} ->
        {:reply, kv, state}

      {:ok, %Kv{lock: true} = kv} ->
        kv = struct(kv, lock: nil)
        exec_op(table, :put, {key, kv})
        {:reply, kv, state}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_cast({table, :sync, target_node, _}, state) do
    case node() do
      ^target_node ->
        :noop

      _ ->
        GenServer.cast({table, target_node}, {table, :put_bulk, :ets.tab2list(table)})
    end

    {:noreply, state}
  end

  def handle_cast({table, :put, key, %Kv{} = kv}, state) do
    true = :ets.insert(table, {key, kv})
    {:noreply, state}
  end

  def handle_cast({table, :put_bulk, [%Kv{}] = kvs}, state) do
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
         kvs <-
           :ets.tab2list(table) |> Enum.filter(fn {_k, value} -> value.node == down_node end),
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

  @spec generate_kv(
          atom(),
          any(),
          integer() | nil,
          boolean() | nil,
          boolean() | nil
        ) :: %Kv{}
  defp generate_kv(node, value, ttl, lock, persist) do
    time = current_nano_time()
    exp = calc_exp(persist, ttl, time)

    %Kv{
      value: value,
      node: node,
      lock: lock,
      exp: exp,
      time: time
    }
  end

  @spec calc_exp(boolean(), integer(), integer()) :: integer() | nil
  defp calc_exp(persist, ttl, time) do
    if !persist and ttl do
      time + ttl * 1_000_000
    else
      nil
    end
  end

  defp lookup_key(table, key) do
    case :ets.lookup(table, key) do
      [{^key, %Kv{} = kv}] -> {:ok, kv}
      [] -> {:error, :not_found}
    end
  end

  defp current_nano_time() do
    System.system_time(:nanosecond)
  end
end
