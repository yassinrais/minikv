defmodule MinikvTest do
  use ExUnit.Case, async: true

  alias Minikv.Kv

  setup do
    {:ok, _pid} = Supervisor.start_link(Minikv.Kvs, name: TestKv)
    {:ok, kv: TestKv, node: node()}
  end

  test "put/set keys values", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_1) == nil

    assert %Kv{val: "put test", node: ^node} = Minikv.Kvs.put(kv, :key_1, "put test")
    assert %Kv{val: "put test", node: ^node} = Minikv.Kvs.get(kv, :key_1)

    assert %Kv{val: "set test", node: ^node} = Minikv.Kvs.set(kv, :key_1, "set test")
    assert %Kv{val: "set test", node: ^node} = Minikv.Kvs.get(kv, :key_1)
  end

  test "delete keys values", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_2) == nil
    assert Minikv.Kvs.delete(kv, :key_2) == nil
    assert %Kv{val: "test", node: ^node} = Minikv.Kvs.put(kv, :key_2, "test")
    assert %Kv{val: "test", node: ^node} = Minikv.Kvs.delete(kv, :key_2)
  end

  test "using invalid keys", %{kv: kv} do
    assert {:invalid_key, _} = Minikv.Kvs.get(kv, nil)
    assert {:invalid_key, _} = Minikv.Kvs.delete(kv, nil)

    assert {:invalid_key, _} = Minikv.Kvs.put(kv, nil, "nil value")
  end

  # TODO: test "sync"
  # TODO: test "clustering"
  # TODO: test "using macro"
end
