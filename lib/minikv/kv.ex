defmodule Minikv.Kv do
  use Supervisor
  alias Minikv.Registry

  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        dbg("use child_spec #{__MODULE__}")
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Minikv.Kv.child_spec(opts)
      end

      def start_link(opts) do
        dbg("use start_link #{__MODULE__}")
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Minikv.Kv.start_link(opts)
      end

      def get(key), do: Minikv.Kv.get(__MODULE__, key)
      def del(key), do: Minikv.Kv.del(__MODULE__, key)
      def put(key, value), do: Minikv.Kv.put(__MODULE__, key, value)
    end
  end

  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

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

  def get(name, key) do
    Registry.get(target_ets_name(name), key)
  end

  def put(name, key, value) do
    Registry.put(target_ets_name(name), key, value)
  end

  def del(name, key) do
    Registry.del(target_ets_name(name), key)
  end

  defp target_ets_name(name) do
    :"#{name}.Kvs"
  end
end
