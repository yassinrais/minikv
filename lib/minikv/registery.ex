defmodule Minikv.Registry do
  use GenServer

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
    {:ok, %{table: opts[:name], opts: opts}}
  end

  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  def put(server, key, value) do
    GenServer.call(server, {:put, key, value})
  end

  def del(server, key) do
    GenServer.call(server, {:del, key})
  end

  def handle_call({_op, nil}, _from, data),
    do: {:reply, {:kv_invalid_key, "nil is not valid keyname"}, data}

  def handle_call({_op, nil, _val}, _from, data),
    do: {:reply, {:kv_invalid_key, "nil is not valid keyname"}, data}

  def handle_call({:get, key}, _from, data) do
    result =
      case :ets.lookup(data.table, key) do
        [{^key, value}] ->
          value

        [] ->
          nil
      end

    {:reply, {:ok, result}, data}
  end

  def handle_call({:put, key, val}, _from, data) do
    true = :ets.insert(data.table, {key, val})
    {:reply, {:ok, val}, data}
  end

  def handle_call({:del, key}, _from, data) do
    result =
      case :ets.lookup(data.table, key) do
        [{^key, val}] ->
          true = :ets.delete(data.table, key)
          val

        [] ->
          nil
      end

    {:reply, {:ok, result}, data}
  end
end
