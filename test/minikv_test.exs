defmodule MinikvTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, _pid} = Supervisor.start_link(Minikv.Kv, name: ExKv)
    {:ok, kv: ExKv}
  end

  test "write keys values", %{kv: kv} do
    assert Minikv.Kv.get(kv, :my_key) == {:ok, nil}
    assert Minikv.Kv.put(kv, :my_key, "cool") == {:ok, "cool"}
    assert Minikv.Kv.get(kv, :my_key) == {:ok, "cool"}
  end

  test "remove keys values", %{kv: kv} do
    assert Minikv.Kv.get(kv, :my_del_key) == {:ok, nil}
    assert Minikv.Kv.del(kv, :my_del_key) == {:ok, nil}
    assert Minikv.Kv.put(kv, :my_del_key, "test") == {:ok, "test"}
    assert Minikv.Kv.del(kv, :my_del_key) == {:ok, "test"}
  end

  test "using invalid keys", %{kv: kv} do
    assert {:kv_invalid_key, "nil is not valid keyname"} == Minikv.Kv.get(kv, nil)
    assert {:kv_invalid_key, "nil is not valid keyname"} == Minikv.Kv.del(kv, nil)

    assert {:kv_invalid_key, "nil is not valid keyname"} ==
             Minikv.Kv.put(kv, nil, "nil value")
  end

  # TODO: test "sync"
  # TODO: test "clustering"
  # TODO: test "using macro"
end
