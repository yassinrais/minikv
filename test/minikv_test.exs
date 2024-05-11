defmodule MinikvTest do
  use ExUnit.Case, async: true

  alias Minikv.Kv

  setup do
    {:ok, _pid} = Supervisor.start_link(Minikv.Kvs, name: TestKv)
    {:ok, kv: TestKv, node: node()}
  end

  test "put/set key-value", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_1) == nil

    assert %Kv{value: "put test", node: ^node} = Minikv.Kvs.put(kv, :key_1, "put test")
    assert %Kv{value: "put test", node: ^node} = Minikv.Kvs.get(kv, :key_1)

    assert %Kv{value: "set test", node: ^node} = Minikv.Kvs.set(kv, :key_1, "set test")
    assert %Kv{value: "set test", node: ^node} = Minikv.Kvs.get(kv, :key_1)
  end

  test "delete key-value", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_2) == nil
    assert Minikv.Kvs.delete(kv, :key_2) == nil

    assert %Kv{value: "del key", node: ^node} = Minikv.Kvs.put(kv, :key_2, "del key")
    assert %Kv{value: "del key", node: ^node} = Minikv.Kvs.delete(kv, :key_2)
  end

  test "expired key-value", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_3) == nil

    assert %Kv{value: "expired key", node: ^node, exp: exp} =
             Minikv.Kvs.put(kv, :key_3, value: "expired key", ttl: -100_000_000)

    assert exp < System.system_time(:nanosecond), "Expiration time is not in the future"

    assert Minikv.Kvs.get(kv, :key_3) == nil
  end

  test "persist key-value", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_4) == nil

    assert %Kv{value: "non persistent key", node: ^node, exp: exp} =
             Minikv.Kvs.put(kv, :key_4, value: "non persistent key", ttl: 100_000_000_000_000)

    assert exp > System.system_time(:nanosecond), "Expiration time is in the future"

    assert %Kv{value: "non persistent key", node: ^node, exp: nil} =
             Minikv.Kvs.persist(kv, :key_4)
  end

  test "lock key-value", %{kv: kv, node: node} do
    assert Minikv.Kvs.get(kv, :key_5) == nil

    assert %Kv{value: "non locked key-value", node: ^node, lock: nil} =
             Minikv.Kvs.put(kv, :key_5, value: "non locked key-value")

    assert %Kv{value: "non locked key-value", node: ^node, lock: true} =
             Minikv.Kvs.lock(kv, :key_5)

    assert %Kv{value: "non locked key-value", node: ^node, lock: true} =
             Minikv.Kvs.get(kv, :key_5)

    assert %Kv{value: "non locked key-value", node: ^node, lock: nil} =
             Minikv.Kvs.unlock(kv, :key_5)

    assert %Kv{value: "non locked key-value", node: ^node, lock: nil} =
             Minikv.Kvs.get(kv, :key_5)
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
