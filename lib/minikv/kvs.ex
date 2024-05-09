defmodule Minikv.Kvs do
  @moduledoc """
  A supervisor for Minikv, providing a key-value store.
  """
  use Supervisor
  alias Minikv.Kv
  alias Minikv.Registry

  @spec child_spec(keyword()) :: map()
  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    name = opts[:name] || raise ArgumentError, "Kv name is required"

    table_name = target_ets_name(name)

    case :ets.info(table_name) do
      :undefined ->
        :ets.new(table_name, [:named_table, :public, :set])

      table_name ->
        table_name
    end

    children = [
      {Registry, [name: table_name]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @type result() :: nil | %Kv{}
  @doc """
  Retrieves a value from the KVS.

  ## Example
      iex> Minikv.Kvs.get(:my_kvs, "my_key")
      %Kv{val: "my_value", node: :node1, time: 123456789}
  """
  @spec get(atom(), binary()) :: result()
  def get(name, key) do
    Registry.get(target_ets_name(name), key)
  end

  @spec put(any(), binary(), any()) :: result()
  @doc """
  Puts a value into the KVS.

  ## Example
      iex> Minikv.Kvs.put(:my_kvs, "my_key", "my_value")
      :ok
  """
  @spec put(atom(), binary(), any()) :: result()
  def put(name, key, value) do
    Registry.put(target_ets_name(name), key, value)
  end

  @doc """
  Deletes a value from the KVS.

  ## Example
      iex> Minikv.Kvs.del(:my_kvs, "my_key")
      :ok
  """
  @spec del(atom(), binary()) :: result()
  def del(name, key) do
    Registry.del(target_ets_name(name), key)
  end

  defp target_ets_name(name) do
    :"#{name}.Kvs"
  end

  @doc """
  A macro to use the KVS in a module.

  ## Example
      defmodule MyExampleKvs do
        use Minikv.Kvs
      end
  """
  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Minikv.Kvs.child_spec(opts)
      end

      def start_link(opts) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Minikv.Kvs.start_link(opts)
      end

      def get(key), do: Minikv.Kvs.get(__MODULE__, key)
      def del(key), do: Minikv.Kvs.del(__MODULE__, key)
      def put(key, value), do: Minikv.Kvs.put(__MODULE__, key, value)
    end
  end
end
