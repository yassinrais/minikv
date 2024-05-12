defmodule Minikv.Kvs do
  @moduledoc """
  A supervisor for Minikv, providing a key-value store.
  """
  use Supervisor
  alias Minikv.Kv
  alias Minikv.Registry

  @type kv() :: Minikv.Kv.t()
  @type result() :: nil | %Kv{}

  @spec child_spec(keyword()) :: map()
  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
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
      {Registry, Keyword.merge(opts, name: table_name)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Retrieves a value from the KVS.

  ## Example
      iex> Minikv.Kvs.get(:my_kvs, "my_key")
      %Kv{value: "my_value", node: :node1, time: 123456789}
  """
  @spec get(atom(), binary()) :: result()
  def get(name, key) do
    Registry.get(target_ets_name(name), key)
  end

  @doc """
  Puts a value into the KVS.

  ## Example
      iex> Minikv.Kvs.put(:my_kvs, "my_key", "my_value")
      :ok
  """
  @spec put(atom(), binary(), kv() | any()) :: result()
  def put(name, key, value_or_opts) do
    Registry.put(target_ets_name(name), key, value_or_opts)
  end

  @doc """
  Puts a value into the KVS.

  ## Example
      iex> Minikv.Kvs.set(:my_kvs, "my_key", "my_value")
      :ok
  """
  @spec set(atom(), binary(), any() | kv()) :: result()
  def set(name, key, value_or_opts) do
    Registry.put(target_ets_name(name), key, value_or_opts)
  end

  @doc """
  Deletes a value from the KVS.

  ## Example
      iex> Minikv.Kvs.delete(:my_kvs, "my_key")
      :ok
  """
  @spec delete(atom(), binary()) :: result()
  def delete(name, key) do
    Registry.delete(target_ets_name(name), key)
  end

  @doc """
  Persist a key value in the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Kvs.start_link(name: :my_registry)
      iex> Minikv.Kvs.delete(registry, "my_key")
      :ok
  """
  @spec persist(atom(), binary()) :: result()
  def persist(name, key) do
    Registry.persist(target_ets_name(name), key)
  end

  @doc """
  Lock a key in the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Kvs.start_link(name: :my_registry)
      iex> Minikv.Kvs.lock(registry, "my_key")
      :ok
  """
  @spec lock(atom(), binary()) :: result()
  def lock(name, key) do
    Registry.lock(target_ets_name(name), key)
  end

  @doc """
  Unlock a key in the registry.

  ## Example
      iex> {:ok, registry} = Minikv.Kvs.start_link(name: :my_registry)
      iex> Minikv.Kvs.lock(registry, "my_key")
      :ok
      iex> Minikv.Kvs.unlock(registry, "my_key")
      :ok
  """
  @spec unlock(atom(), binary()) :: result()
  def unlock(name, key) do
    Registry.unlock(target_ets_name(name), key)
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
      def delete(key), do: Minikv.Kvs.delete(__MODULE__, key)
      def put(key, value), do: Minikv.Kvs.put(__MODULE__, key, value)

      def persist(key, value), do: Minikv.Kvs.persist(__MODULE__, key, value)

      def lock(key, value), do: Minikv.Kvs.lock(__MODULE__, key, value)
      def unlock(key, value), do: Minikv.Kvs.unlock(__MODULE__, key, value)
    end
  end
end
